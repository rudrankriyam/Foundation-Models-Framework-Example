import ArgumentParser
import Foundation
import FoundationModels
import FoundationModelsTools

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

#if canImport(Contacts)
import Contacts
#endif

#if canImport(EventKit)
import EventKit
#endif

#if canImport(CoreLocation)
import CoreLocation
#endif

#if canImport(MusicKit)
import MusicKit
#endif

#if canImport(Speech)
import Speech
#endif

#if canImport(AVFoundation)
import AVFoundation
#endif

#if canImport(HealthKit)
import HealthKit
#endif

@available(macOS 10.15, macCatalyst 13, iOS 13, tvOS 13, watchOS 6, *)
struct FoundationLabCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "fm",
        abstract: "Command-line access to Foundation Models workflows.",
        subcommands: [
            AboutCommand.self,
            DiagnosticsCommand.self,
            ChatCommand.self,
            ExamplesCommand.self,
            ToolsCommand.self,
            SchemasCommand.self,
            LanguagesCommand.self,
            RagCommand.self,
            HealthCommand.self,
            VoiceCommand.self
        ],
        defaultSubcommand: AboutCommand.self
    )
}

// MARK: - Global Option Set

struct GlobalOptions: ParsableArguments {
    @Flag(name: .long, help: "Output machine-readable JSON.")
    var json = false

    @Flag(name: .long, help: "Include additional debugging metadata.")
    var verbose = false

    @Flag(name: .long, help: "Suppress non-essential human output.")
    var quiet = false

    @Flag(name: .customLong("no-color"), help: "Disable ANSI colors in output.")
    var noColor = false

    @Option(name: .long, help: "Timeout (seconds) for model/tool operations.")
    var timeout: Int?

    @Flag(name: .long, help: "Show request shape without executing.")
    var dryRun = false
}

enum ChatSamplingOption: String, ExpressibleByArgument {
    case `default`
    case greedy
    case topK = "top-k"
}

enum GuardrailsOption: String, ExpressibleByArgument {
    case `default`
    case permissive
}

enum GenerationSamplingMode: String, ExpressibleByArgument {
    case greedy
    case topK = "top-k"
    case topP = "top-p"
}

enum ReminderPriorityOption: String, ExpressibleByArgument {
    case none
    case low
    case medium
    case high
}

enum CLICommandError: LocalizedError {
    case timedOut(Int)
    case invalidInput(String)
    case capabilityUnavailable(capability: String, reason: String, remediation: String)

    var errorDescription: String? {
        switch self {
        case .timedOut(let seconds):
            return "Operation timed out after \(seconds) second(s)."
        case .invalidInput(let message):
            return message
        case let .capabilityUnavailable(capability, reason, remediation):
            return "\(capability) unavailable: \(reason). \(remediation)"
        }
    }
}

struct CapabilityStatus {
    let available: Bool
    let reason: String?
    let remediation: String?

    var payload: [String: Any] {
        [
            "available": available,
            "reason": reason ?? "",
            "remediation": remediation ?? ""
        ]
    }
}

struct ModelAvailabilitySnapshot {
    let status: String
    let reason: String?
    let remediation: String?
}

struct StoredMessage: Codable {
    let role: String
    let content: String
    let timestamp: Date
}

struct StoredSessionState: Codable {
    var messages: [StoredMessage]
    var updatedAt: Date

    static let empty = StoredSessionState(messages: [], updatedAt: Date())
}

struct RAGDocument: Codable {
    let id: UUID
    let title: String
    let content: String
    let sourceType: String
    let source: String
    let indexedAt: Date
}

struct RAGSearchHit {
    let document: RAGDocument
    let score: Double
    let snippet: String
}

// MARK: - Core Helpers

enum CLIPrinter {
    static func emitHuman(_ message: String, global: GlobalOptions) {
        guard !global.json && !global.quiet else { return }
        print(message)
    }

    static func emit(payload: [String: Any], human: String, global: GlobalOptions) {
        if global.json {
            emitJSON(payload)
        } else if !global.quiet {
            print(human)
        }
    }

    static func emitError(_ error: Error, global: GlobalOptions) {
        if global.json {
            emitJSON(errorPayload(for: error))
            return
        }

        let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        fputs("Error: \(message)\n", stderr)
    }

    static func emitJSON(_ object: Any) {
        if JSONSerialization.isValidJSONObject(object),
           let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
           let text = String(data: data, encoding: .utf8) {
            print(text)
        } else {
            print("{\"status\":\"error\",\"message\":\"Failed to render JSON output.\"}")
        }
    }

    private static func errorPayload(for error: Error) -> [String: Any] {
        if case let CLICommandError.capabilityUnavailable(capability, reason, remediation) = error {
            return [
                "status": "error",
                "error": "capability_unavailable",
                "capability": capability,
                "reason": reason,
                "remediation": remediation
            ]
        }

        let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        return [
            "status": "error",
            "error": "command_failed",
            "message": message
        ]
    }
}

func fail(_ error: Error, global: GlobalOptions) throws -> Never {
    CLIPrinter.emitError(error, global: global)
    throw ExitCode.failure
}

func withTimeout<T>(seconds: Int?, operation: @escaping () async throws -> T) async throws -> T {
    guard let seconds, seconds > 0 else {
        return try await operation()
    }

    return try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds) * 1_000_000_000)
            throw CLICommandError.timedOut(seconds)
        }

        guard let first = try await group.next() else {
            throw CLICommandError.timedOut(seconds)
        }
        group.cancelAll()
        return first
    }
}

func hasInteractiveTerminal() -> Bool {
#if canImport(Darwin) || canImport(Glibc)
    isatty(fileno(stdin)) != 0 && isatty(fileno(stdout)) != 0
#else
    false
#endif
}

func requireInteractiveTerminal(command: String) throws {
    guard hasInteractiveTerminal() else {
        throw CLICommandError.invalidInput(
            "`\(command)` requires an interactive terminal. Use non-interactive commands (for example, `fm chat send --message ...`) for automation."
        )
    }
}

func expandedPath(_ rawPath: String) -> String {
    NSString(string: rawPath).expandingTildeInPath
}

func resolveSessionURL(_ path: String?) -> URL? {
    guard let path, !path.isEmpty else {
        return nil
    }
    return URL(fileURLWithPath: expandedPath(path))
}

func loadSession(path: String?) throws -> StoredSessionState {
    guard let url = resolveSessionURL(path) else {
        return .empty
    }
    guard FileManager.default.fileExists(atPath: url.path) else {
        return .empty
    }

    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode(StoredSessionState.self, from: data)
}

func saveSession(_ state: StoredSessionState, path: String?) throws {
    guard let url = resolveSessionURL(path) else {
        return
    }
    let parent = url.deletingLastPathComponent()
    try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
    let data = try JSONEncoder().encode(state)
    try data.write(to: url, options: .atomic)
}

func resetSession(path: String?) throws {
    guard let url = resolveSessionURL(path) else {
        // No explicit session file means there is nothing persisted to clear.
        return
    }

    if FileManager.default.fileExists(atPath: url.path) {
        try FileManager.default.removeItem(at: url)
    }
}

func chatPromptWithHistory(message: String, history: [StoredMessage]) -> String {
    guard !history.isEmpty else {
        return message
    }

    let transcript = history.suffix(20).map { entry in
        "\(entry.role.capitalized): \(entry.content)"
    }.joined(separator: "\n")

    return """
    Continue this conversation naturally.

    Conversation so far:
    \(transcript)

    User: \(message)
    """
}

func createModel(guardrails: GuardrailsOption) -> SystemLanguageModel {
    let selectedGuardrails: SystemLanguageModel.Guardrails = switch guardrails {
    case .default:
        .default
    case .permissive:
        .permissiveContentTransformations
    }
    return SystemLanguageModel(useCase: .general, guardrails: selectedGuardrails)
}

func createChatGenerationOptions(
    sampling: ChatSamplingOption,
    topK: Int,
    fixedSeed: Bool,
    seed: UInt64?
) -> GenerationOptions {
    switch sampling {
    case .default:
        return GenerationOptions()
    case .greedy:
        return GenerationOptions(sampling: .greedy)
    case .topK:
        let resolvedSeed = fixedSeed ? (seed ?? 42) : nil
        return GenerationOptions(sampling: .random(top: topK, seed: resolvedSeed))
    }
}

func modelAvailabilitySnapshot() -> ModelAvailabilitySnapshot {
    switch SystemLanguageModel.default.availability {
    case .available:
        return ModelAvailabilitySnapshot(status: "available", reason: nil, remediation: nil)
    case .unavailable(let unavailableReason):
        let rawReason = String(describing: unavailableReason)
        let lowered = rawReason.lowercased()
        let normalizedReason: String
        let remediation: String

        if lowered.contains("device") || lowered.contains("eligible") || lowered.contains("supported") {
            normalizedReason = "deviceNotEligible"
            remediation = "Use a compatible Apple Silicon device that supports Apple Intelligence."
        } else if lowered.contains("intelligence") || lowered.contains("enabled") || lowered.contains("settings") {
            normalizedReason = "appleIntelligenceNotEnabled"
            remediation = "Enable Apple Intelligence in system settings."
        } else if lowered.contains("notready") || lowered.contains("preparing") || lowered.contains("download") {
            normalizedReason = "modelNotReady"
            remediation = "Wait for model assets to finish preparing, then retry."
        } else {
            normalizedReason = "unknown"
            remediation = "Verify macOS 26+, Apple Intelligence support, and retry."
        }

        return ModelAvailabilitySnapshot(
            status: "unavailable",
            reason: normalizedReason,
            remediation: remediation
        )
    @unknown default:
        return ModelAvailabilitySnapshot(
            status: "unavailable",
            reason: "unknown",
            remediation: "Verify system compatibility and Apple Intelligence settings."
        )
    }
}

func runResponse(
    prompt: String,
    instructions: String?,
    model: SystemLanguageModel,
    options: GenerationOptions,
    global: GlobalOptions
) async throws -> String {
    if global.dryRun {
        return "[dry-run] Model prompt prepared."
    }

    let session = if let instructions, !instructions.isEmpty {
        LanguageModelSession(model: model, instructions: Instructions(instructions))
    } else {
        LanguageModelSession(model: model)
    }

    return try await withTimeout(seconds: global.timeout) {
        let response = try await session.respond(to: Prompt(prompt), options: options)
        return response.content
    }
}

func runStreamingResponse(
    prompt: String,
    instructions: String?,
    model: SystemLanguageModel,
    options: GenerationOptions,
    global: GlobalOptions
) async throws -> String {
    if global.dryRun {
        return "[dry-run] Stream request prepared."
    }

    let session = if let instructions, !instructions.isEmpty {
        LanguageModelSession(model: model, instructions: Instructions(instructions))
    } else {
        LanguageModelSession(model: model)
    }

    return try await withTimeout(seconds: global.timeout) {
        var previous = ""
        var final = ""
        for try await snapshot in session.streamResponse(to: Prompt(prompt), options: options) {
            let current = snapshot.content
            if !global.json && !global.quiet {
                if current.hasPrefix(previous) {
                    let delta = String(current.dropFirst(previous.count))
                    if !delta.isEmpty, let data = delta.data(using: .utf8) {
                        FileHandle.standardOutput.write(data)
                    }
                } else if let data = ("\n\(current)").data(using: .utf8) {
                    FileHandle.standardOutput.write(data)
                }
            }
            previous = current
            final = current
        }

        if !global.json && !global.quiet, let newline = "\n".data(using: .utf8) {
            FileHandle.standardOutput.write(newline)
        }

        return final
    }
}

func runToolPrompt(
    tools: [any Tool],
    prompt: String,
    instructions: String?,
    global: GlobalOptions
) async throws -> String {
    if global.dryRun {
        return "[dry-run] Tool invocation prepared."
    }

    let session = if let instructions, !instructions.isEmpty {
        LanguageModelSession(tools: tools, instructions: Instructions(instructions))
    } else {
        LanguageModelSession(tools: tools)
    }

    return try await withTimeout(seconds: global.timeout) {
        let response = try await session.respond(to: Prompt(prompt))
        return response.content
    }
}

// MARK: - Capability Checks

func contactsCapability() -> CapabilityStatus {
#if canImport(Contacts)
    switch CNContactStore.authorizationStatus(for: .contacts) {
    case .authorized:
        return CapabilityStatus(available: true, reason: nil, remediation: nil)
    case .notDetermined:
        return CapabilityStatus(
            available: false,
            reason: "contactsPermissionNotDetermined",
            remediation: "Grant Contacts access for this terminal host in Privacy & Security."
        )
    case .denied, .restricted:
        return CapabilityStatus(
            available: false,
            reason: "contactsPermissionDenied",
            remediation: "Enable Contacts access in Privacy & Security settings."
        )
    @unknown default:
        return CapabilityStatus(
            available: false,
            reason: "contactsPermissionUnknown",
            remediation: "Check Contacts permission state and retry."
        )
    }
#else
    return CapabilityStatus(
        available: false,
        reason: "contactsFrameworkUnavailable",
        remediation: "Contacts framework is unavailable on this platform."
    )
#endif
}

func calendarCapability() -> CapabilityStatus {
#if canImport(EventKit)
    switch EKEventStore.authorizationStatus(for: .event) {
    case .fullAccess, .writeOnly, .authorized:
        return CapabilityStatus(available: true, reason: nil, remediation: nil)
    case .notDetermined:
        return CapabilityStatus(
            available: false,
            reason: "calendarPermissionNotDetermined",
            remediation: "Grant Calendar access for this terminal host in Privacy & Security."
        )
    case .denied, .restricted:
        return CapabilityStatus(
            available: false,
            reason: "calendarPermissionDenied",
            remediation: "Enable Calendar access in Privacy & Security settings."
        )
    @unknown default:
        return CapabilityStatus(
            available: false,
            reason: "calendarPermissionUnknown",
            remediation: "Check Calendar permission state and retry."
        )
    }
#else
    return CapabilityStatus(
        available: false,
        reason: "eventKitUnavailable",
        remediation: "EventKit framework is unavailable on this platform."
    )
#endif
}

func remindersCapability() -> CapabilityStatus {
#if canImport(EventKit)
    switch EKEventStore.authorizationStatus(for: .reminder) {
    case .fullAccess, .writeOnly, .authorized:
        return CapabilityStatus(available: true, reason: nil, remediation: nil)
    case .notDetermined:
        return CapabilityStatus(
            available: false,
            reason: "remindersPermissionNotDetermined",
            remediation: "Grant Reminders access for this terminal host in Privacy & Security."
        )
    case .denied, .restricted:
        return CapabilityStatus(
            available: false,
            reason: "remindersPermissionDenied",
            remediation: "Enable Reminders access in Privacy & Security settings."
        )
    @unknown default:
        return CapabilityStatus(
            available: false,
            reason: "remindersPermissionUnknown",
            remediation: "Check Reminders permission state and retry."
        )
    }
#else
    return CapabilityStatus(
        available: false,
        reason: "eventKitUnavailable",
        remediation: "EventKit framework is unavailable on this platform."
    )
#endif
}

func locationCapability() -> CapabilityStatus {
#if canImport(CoreLocation)
    let status = CLLocationManager().authorizationStatus
    switch status {
    case .authorizedAlways, .authorizedWhenInUse:
        return CapabilityStatus(available: true, reason: nil, remediation: nil)
    case .notDetermined:
        return CapabilityStatus(
            available: false,
            reason: "locationPermissionNotDetermined",
            remediation: "Grant Location access in Privacy & Security settings."
        )
    case .denied, .restricted:
        return CapabilityStatus(
            available: false,
            reason: "locationPermissionDenied",
            remediation: "Enable Location Services and app permission in Privacy & Security."
        )
    @unknown default:
        return CapabilityStatus(
            available: false,
            reason: "locationPermissionUnknown",
            remediation: "Check Location permission state and retry."
        )
    }
#else
    return CapabilityStatus(
        available: false,
        reason: "coreLocationUnavailable",
        remediation: "CoreLocation framework is unavailable on this platform."
    )
#endif
}

func healthCapability() -> CapabilityStatus {
#if canImport(HealthKit)
    if HKHealthStore.isHealthDataAvailable() {
        return CapabilityStatus(available: true, reason: nil, remediation: nil)
    }
    return CapabilityStatus(
        available: false,
        reason: "healthDataUnavailable",
        remediation: "Use a system with Health data availability and proper authorization."
    )
#else
    return CapabilityStatus(
        available: false,
        reason: "healthKitUnavailable",
        remediation: "HealthKit framework is unavailable on this platform."
    )
#endif
}

func musicCapability() async -> CapabilityStatus {
#if canImport(MusicKit)
    let status = MusicAuthorization.currentStatus
    switch status {
    case .authorized:
        do {
            let subscription = try await MusicSubscription.current
            if subscription.canPlayCatalogContent {
                return CapabilityStatus(available: true, reason: nil, remediation: nil)
            }
            return CapabilityStatus(
                available: false,
                reason: "appleMusicSubscriptionMissing",
                remediation: "Use an active Apple Music subscription for catalog queries."
            )
        } catch {
            return CapabilityStatus(
                available: false,
                reason: "appleMusicSubscriptionCheckFailed",
                remediation: "Retry later or verify Music account state."
            )
        }
    case .notDetermined:
        return CapabilityStatus(
            available: false,
            reason: "appleMusicPermissionNotDetermined",
            remediation: "Grant Apple Music access in Privacy & Security settings."
        )
    case .denied, .restricted:
        return CapabilityStatus(
            available: false,
            reason: "appleMusicPermissionDenied",
            remediation: "Enable Apple Music access in system settings."
        )
    @unknown default:
        return CapabilityStatus(
            available: false,
            reason: "appleMusicPermissionUnknown",
            remediation: "Check Apple Music permission and subscription status."
        )
    }
#else
    return CapabilityStatus(
        available: false,
        reason: "musicKitUnavailable",
        remediation: "MusicKit is unavailable on this platform."
    )
#endif
}

func speechCapability() -> CapabilityStatus {
#if canImport(Speech)
    switch SFSpeechRecognizer.authorizationStatus() {
    case .authorized:
        return CapabilityStatus(available: true, reason: nil, remediation: nil)
    case .notDetermined:
        return CapabilityStatus(
            available: false,
            reason: "speechPermissionNotDetermined",
            remediation: "Grant Speech Recognition permission in Privacy & Security."
        )
    case .denied, .restricted:
        return CapabilityStatus(
            available: false,
            reason: "speechPermissionDenied",
            remediation: "Enable Speech Recognition permission in settings."
        )
    @unknown default:
        return CapabilityStatus(
            available: false,
            reason: "speechPermissionUnknown",
            remediation: "Check Speech Recognition permission and retry."
        )
    }
#else
    return CapabilityStatus(
        available: false,
        reason: "speechFrameworkUnavailable",
        remediation: "Speech framework is unavailable on this platform."
    )
#endif
}

func microphoneCapability() -> CapabilityStatus {
#if canImport(AVFoundation)
    switch AVCaptureDevice.authorizationStatus(for: .audio) {
    case .authorized:
        return CapabilityStatus(available: true, reason: nil, remediation: nil)
    case .notDetermined:
        return CapabilityStatus(
            available: false,
            reason: "microphonePermissionNotDetermined",
            remediation: "Grant microphone permission in Privacy & Security."
        )
    case .denied, .restricted:
        return CapabilityStatus(
            available: false,
            reason: "microphonePermissionDenied",
            remediation: "Enable microphone permission in Privacy & Security."
        )
    @unknown default:
        return CapabilityStatus(
            available: false,
            reason: "microphonePermissionUnknown",
            remediation: "Check microphone permission and retry."
        )
    }
#else
    return CapabilityStatus(
        available: false,
        reason: "avFoundationUnavailable",
        remediation: "AVFoundation is unavailable on this platform."
    )
#endif
}

func requireCapability(_ capability: String, status: CapabilityStatus) throws {
    guard status.available else {
        throw CLICommandError.capabilityUnavailable(
            capability: capability,
            reason: status.reason ?? "unknown",
            remediation: status.remediation ?? "Resolve permission or environment issues and retry."
        )
    }
}

// MARK: - Search1 API

struct Search1Request: Encodable {
    let query: String
    let searchService: String
    let maxResults: Int
    let crawlResults: Int
    let image: Bool
    let includeSites: [String]
    let excludeSites: [String]
    let language: String
    let timeRange: String

    enum CodingKeys: String, CodingKey {
        case query
        case searchService = "search_service"
        case maxResults = "max_results"
        case crawlResults = "crawl_results"
        case image
        case includeSites = "include_sites"
        case excludeSites = "exclude_sites"
        case language
        case timeRange = "time_range"
    }
}

struct Search1Response: Decodable {
    let results: [Search1Result]
}

struct Search1Result: Decodable {
    let title: String
    let link: String
    let snippet: String?
    let content: String?
}

func searchWeb(query: String, maxResults: Int) async throws -> [Search1Result] {
    guard let url = URL(string: "https://api.search1api.com/search") else {
        throw CLICommandError.invalidInput("Invalid Search1API URL.")
    }

    let payload = Search1Request(
        query: query,
        searchService: "google",
        maxResults: maxResults,
        crawlResults: 0,
        image: false,
        includeSites: [],
        excludeSites: [],
        language: "en",
        timeRange: "year"
    )

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(payload)

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let http = response as? HTTPURLResponse else {
        throw CLICommandError.invalidInput("Search API returned an invalid response.")
    }
    guard (200...299).contains(http.statusCode) else {
        throw CLICommandError.invalidInput("Search API returned HTTP \(http.statusCode).")
    }

    let decoded = try JSONDecoder().decode(Search1Response.self, from: data)
    return decoded.results
}

// MARK: - Dynamic Schema Helpers

func dynamicProperty(
    name: String,
    schema: DynamicGenerationSchema,
    description: String? = nil,
    optional: Bool = false
) -> DynamicGenerationSchema.Property {
    DynamicGenerationSchema.Property(
        name: name,
        description: description,
        schema: schema,
        isOptional: optional
    )
}

func typedProperty<T: Generable>(
    _ name: String,
    type: T.Type,
    description: String? = nil,
    optional: Bool = false
) -> DynamicGenerationSchema.Property {
    DynamicGenerationSchema.Property(
        name: name,
        description: description,
        schema: DynamicGenerationSchema(type: type),
        isOptional: optional
    )
}

func generatedObject(from content: GeneratedContent) throws -> Any {
    switch content.kind {
    case .string(let value):
        return value
    case .number(let value):
        return value
    case .bool(let value):
        return value
    case .null:
        return NSNull()
    case .array(let values):
        return try values.map { try generatedObject(from: $0) }
    case .structure(let properties, let orderedKeys):
        var object: [String: Any] = [:]
        for key in orderedKeys {
            if let value = properties[key] {
                object[key] = try generatedObject(from: value)
            }
        }
        return object
    @unknown default:
        return String(describing: content)
    }
}

func formattedJSONString(from object: Any, pretty: Bool) -> String {
    guard JSONSerialization.isValidJSONObject(object),
          let data = try? JSONSerialization.data(
              withJSONObject: object,
              options: pretty ? [.prettyPrinted, .sortedKeys] : []
          ),
          let text = String(data: data, encoding: .utf8) else {
        return String(describing: object)
    }
    return text
}

// MARK: - RAG Store

let ragStorageURL: URL = {
    let home = FileManager.default.homeDirectoryForCurrentUser
    return home.appendingPathComponent(".fm/rag_store.json")
}()

func loadRAGDocuments() throws -> [RAGDocument] {
    let legacyURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".foundationlab/rag_store.json")

    if !FileManager.default.fileExists(atPath: ragStorageURL.path),
       FileManager.default.fileExists(atPath: legacyURL.path) {
        let legacyData = try Data(contentsOf: legacyURL)
        return try JSONDecoder().decode([RAGDocument].self, from: legacyData)
    }

    guard FileManager.default.fileExists(atPath: ragStorageURL.path) else {
        return []
    }
    let data = try Data(contentsOf: ragStorageURL)
    return try JSONDecoder().decode([RAGDocument].self, from: data)
}

func saveRAGDocuments(_ docs: [RAGDocument]) throws {
    let parent = ragStorageURL.deletingLastPathComponent()
    try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
    let data = try JSONEncoder().encode(docs)
    try data.write(to: ragStorageURL, options: .atomic)
}

func tokenize(_ text: String) -> [String] {
    text.lowercased()
        .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
        .map(String.init)
        .filter { $0.count > 2 }
}

func snippet(content: String, queryTokens: [String]) -> String {
    let lowered = content.lowercased()
    for token in queryTokens {
        if let range = lowered.range(of: token) {
            let index = lowered.distance(from: lowered.startIndex, to: range.lowerBound)
            let start = max(0, index - 120)
            let end = min(content.count, index + 120)
            let startIndex = content.index(content.startIndex, offsetBy: start)
            let endIndex = content.index(content.startIndex, offsetBy: end)
            return String(content[startIndex..<endIndex]).replacingOccurrences(of: "\n", with: " ")
        }
    }

    return String(content.prefix(240)).replacingOccurrences(of: "\n", with: " ")
}

func searchRAG(query: String, documents: [RAGDocument], limit: Int = 5) -> [RAGSearchHit] {
    let queryTokens = tokenize(query)
    guard !queryTokens.isEmpty else { return [] }

    let scored = documents.compactMap { doc -> RAGSearchHit? in
        let text = doc.content.lowercased()
        let matches = Set(queryTokens).filter { text.contains($0) }.count
        guard matches > 0 else { return nil }
        let score = Double(matches) / Double(max(Set(queryTokens).count, 1))
        return RAGSearchHit(
            document: doc,
            score: score,
            snippet: snippet(content: doc.content, queryTokens: queryTokens)
        )
    }

    return scored.sorted { lhs, rhs in
        if lhs.score == rhs.score {
            return lhs.document.indexedAt > rhs.document.indexedAt
        }
        return lhs.score > rhs.score
    }.prefix(limit).map { $0 }
}

let ragSampleDocuments: [(title: String, text: String)] = [
    (
        "Swift Concurrency",
        """
        Swift's concurrency model provides async/await, actors, and structured concurrency.
        Task groups allow parallel execution while preserving cancellation propagation.
        """
    ),
    (
        "Foundation Models",
        """
        Foundation Models enable on-device Apple Intelligence features.
        LanguageModelSession supports prompts, streaming, and structured generation.
        """
    ),
    (
        "HealthKit Basics",
        """
        HealthKit stores health and fitness metrics with explicit user authorization.
        Common metrics include steps, heart rate, sleep, active energy, and distance.
        """
    )
]

// MARK: - Shared Models

@Generable
struct BookRecommendation {
    @Guide(description: "The title of the book")
    let title: String
    @Guide(description: "The author's name")
    let author: String
    @Guide(description: "A brief description in 2-3 sentences")
    let description: String
    @Guide(description: "Genre of the book")
    let genre: Genre
}

@Generable
enum Genre {
    case fiction
    case nonFiction
    case mystery
    case romance
    case sciFi
    case fantasy
    case biography
    case history
}

@Generable
struct JournalEntrySummary {
    @Guide(description: "A gentle journaling prompt inspired by the user's mood and sleep.")
    let prompt: String
    @Guide(description: "A short compassionate message.")
    let upliftingMessage: String
    @Guide(description: "Two to three sentence starters.", .count(2...3))
    let sentenceStarters: [String]
    @Guide(description: "Exactly three summary bullets.", .count(3...3))
    let summaryBullets: [String]
    @Guide(description: "Themes or tags.", .count(3...5))
    let themes: [String]
}

@Generable
struct StoryOutline {
    @Guide(description: "Story title")
    let title: String
    @Guide(description: "Main character description")
    let protagonist: String
    @Guide(description: "Central conflict")
    let conflict: String
    @Guide(description: "Setting")
    let setting: String
    @Guide(description: "Genre")
    let genre: StoryGenre
    @Guide(description: "Major themes")
    let themes: [String]
}

@Generable
enum StoryGenre {
    case adventure
    case mystery
    case romance
    case thriller
    case fantasy
    case sciFi
    case horror
    case comedy
}

@Generable
struct ProductReview {
    @Guide(description: "Product name")
    let productName: String
    @Guide(description: "Rating from 1 to 5")
    let rating: Int
    @Guide(description: "Review text between 50-200 words")
    let reviewText: String
    @Guide(description: "Recommendation summary")
    let recommendation: String
    @Guide(description: "Pros list")
    let pros: [String]
    @Guide(description: "Cons list")
    let cons: [String]
}

@Generable
struct NutritionParseResult {
    @Guide(description: "The food name")
    let foodName: String
    @Guide(description: "Estimated calories")
    let calories: Int
    @Guide(description: "Protein grams")
    let proteinGrams: Int
    @Guide(description: "Carbs grams")
    let carbsGrams: Int
    @Guide(description: "Fat grams")
    let fatGrams: Int
}

// MARK: - Health Analysis Tool

struct HealthAnalysisTool: Tool {
    let name = "analyzeHealthMetrics"
    let description = "Analyze health metrics to provide trends and recommendations."

    @Generable
    struct Arguments {
        @Guide(description: "Type: daily, weekly, trends, correlations, comprehensive")
        var analysisType: String
        @Guide(description: "Optional focus metrics, comma-separated")
        var focusMetrics: String?
        @Guide(description: "Number of days")
        var daysToAnalyze: Int?
        @Guide(description: "Include predictions")
        var includePredictions: Bool?
    }

    func call(arguments: Arguments) async throws -> some PromptRepresentable {
        let analysisType = arguments.analysisType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let days = arguments.daysToAnalyze ?? 7
        guard !analysisType.isEmpty else {
            return GeneratedContent(properties: [
                "status": "error",
                "message": "Analysis type cannot be empty."
            ])
        }

        return GeneratedContent(properties: [
            "status": "success",
            "analysisType": analysisType,
            "days": days,
            "focusMetrics": arguments.focusMetrics ?? "",
            "includePredictions": arguments.includePredictions ?? false,
            "summary": "Generated a baseline \(analysisType) analysis payload."
        ])
    }
}

// MARK: - About

struct AboutCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "about",
        abstract: "Show CLI and environment details."
    )

    @OptionGroup var global: GlobalOptions

    mutating func run() async throws {
        let payload: [String: Any] = [
            "name": "fm",
            "version": "0.1.0",
            "platform": "macOS 26+",
            "status": "preview",
            "features": [
                "diagnostics",
                "chat",
                "examples",
                "tools",
                "schemas",
                "languages",
                "rag",
                "health",
                "voice"
            ]
        ]
        let human = """
        fm (preview)
        Platform: macOS 26+
        Feature groups: diagnostics, chat, examples, tools, schemas, languages, rag, health, voice
        """
        CLIPrinter.emit(payload: payload, human: human, global: global)
    }
}

// MARK: - Diagnostics

struct DiagnosticsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "diagnostics",
        abstract: "Inspect runtime readiness and capability gates.",
        subcommands: [
            DiagnosticsModelAvailabilityCommand.self,
            DiagnosticsCapabilitiesCommand.self
        ]
    )
}

struct DiagnosticsModelAvailabilityCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "model-availability",
        abstract: "Check Apple Intelligence model availability."
    )
    @OptionGroup var global: GlobalOptions

    mutating func run() async throws {
        let snapshot = modelAvailabilitySnapshot()
        let payload: [String: Any] = [
            "status": snapshot.status,
            "reason": snapshot.reason ?? "",
            "remediation": snapshot.remediation ?? ""
        ]
        let human = """
        Status: \(snapshot.status)
        Reason: \(snapshot.reason ?? "none")
        Remediation: \(snapshot.remediation ?? "none")
        """
        CLIPrinter.emit(payload: payload, human: human, global: global)
    }
}

struct DiagnosticsCapabilitiesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "capabilities",
        abstract: "Show aggregated capability snapshot."
    )
    @OptionGroup var global: GlobalOptions

    mutating func run() async throws {
        let availability = modelAvailabilitySnapshot()
        let contacts = contactsCapability()
        let calendar = calendarCapability()
        let reminders = remindersCapability()
        let location = locationCapability()
        let health = healthCapability()
        let music = await musicCapability()
        let speech = speechCapability()
        let mic = microphoneCapability()

        let payload: [String: Any] = [
            "foundationModel": [
                "available": availability.status == "available",
                "reason": availability.reason ?? "",
                "remediation": availability.remediation ?? ""
            ],
            "tools": [
                "weather": ["available": true],
                "webSearch": ["available": true],
                "webMetadata": ["available": true],
                "contacts": contacts.payload,
                "calendar": calendar.payload,
                "reminders": reminders.payload,
                "location": location.payload,
                "health": health.payload,
                "music": music.payload
            ],
            "voice": [
                "speechRecognition": speech.payload,
                "microphone": mic.payload
            ]
        ]

        let human = """
        Foundation model: \(availability.status)
        Tools: weather/webSearch/webMetadata available; permission-gated tools include contacts/calendar/reminders/location/health/music.
        Voice: speech=\(speech.available), microphone=\(mic.available)
        """
        CLIPrinter.emit(payload: payload, human: human, global: global)
    }
}

// MARK: - Chat

struct ChatCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "chat",
        abstract: "Chat with the model (non-interactive by default).",
        subcommands: [
            ChatSendCommand.self,
            ChatStreamCommand.self,
            ChatInteractiveCommand.self,
            ChatResetCommand.self
        ],
        defaultSubcommand: ChatSendCommand.self
    )
}

struct ChatSendCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "send",
        abstract: "Send a single message and receive a single response."
    )

    @Option(name: .long) var message: String
    @Option(name: .long) var instructions: String?
    @Option(name: .long, help: "default | greedy | top-k") var sampling: ChatSamplingOption = .default
    @Option(name: .long) var topK: Int = 50
    @Flag(name: .long) var fixedSeed = false
    @Option(name: .long) var seed: UInt64?
    @Option(name: .long, help: "default | permissive") var guardrails: GuardrailsOption = .default
    @Option(name: .long) var session: String?
    @OptionGroup var global: GlobalOptions

    mutating func run() async throws {
        do {
            guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw CLICommandError.invalidInput("Please provide a non-empty --message.")
            }

            var state = try loadSession(path: session)
            let prompt = chatPromptWithHistory(message: message, history: state.messages)
            let model = createModel(guardrails: guardrails)
            let options = createChatGenerationOptions(
                sampling: sampling,
                topK: topK,
                fixedSeed: fixedSeed,
                seed: seed
            )

            let response = try await runResponse(
                prompt: prompt,
                instructions: instructions,
                model: model,
                options: options,
                global: global
            )

            state.messages.append(StoredMessage(role: "user", content: message, timestamp: Date()))
            state.messages.append(StoredMessage(role: "assistant", content: response, timestamp: Date()))
            state.updatedAt = Date()
            try saveSession(state, path: session)

            let payload: [String: Any] = [
                "status": "success",
                "mode": "send",
                "response": response
            ]
            CLIPrinter.emit(payload: payload, human: response, global: global)
        } catch {
            try fail(error, global: global)
        }
    }
}

struct ChatStreamCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "stream",
        abstract: "Stream response tokens to stdout."
    )

    @Option(name: .long) var message: String
    @Option(name: .long) var instructions: String?
    @Option(name: .long, help: "default | greedy | top-k") var sampling: ChatSamplingOption = .default
    @Option(name: .long) var topK: Int = 50
    @Flag(name: .long) var fixedSeed = false
    @Option(name: .long) var seed: UInt64?
    @Option(name: .long, help: "default | permissive") var guardrails: GuardrailsOption = .default
    @Option(name: .long) var session: String?
    @OptionGroup var global: GlobalOptions

    mutating func run() async throws {
        do {
            guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw CLICommandError.invalidInput("Please provide a non-empty --message.")
            }

            var state = try loadSession(path: session)
            let prompt = chatPromptWithHistory(message: message, history: state.messages)
            let model = createModel(guardrails: guardrails)
            let options = createChatGenerationOptions(
                sampling: sampling,
                topK: topK,
                fixedSeed: fixedSeed,
                seed: seed
            )

            let response = try await runStreamingResponse(
                prompt: prompt,
                instructions: instructions,
                model: model,
                options: options,
                global: global
            )

            state.messages.append(StoredMessage(role: "user", content: message, timestamp: Date()))
            state.messages.append(StoredMessage(role: "assistant", content: response, timestamp: Date()))
            state.updatedAt = Date()
            try saveSession(state, path: session)

            if global.json {
                CLIPrinter.emitJSON([
                    "status": "success",
                    "mode": "stream",
                    "response": response
                ])
            }
        } catch {
            try fail(error, global: global)
        }
    }
}

struct ChatInteractiveCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "interactive",
        abstract: "Open an interactive multi-turn chat REPL."
    )

    @Option(name: .long) var instructions: String?
    @Option(name: .long, help: "default | greedy | top-k") var sampling: ChatSamplingOption = .default
    @Option(name: .long) var topK: Int = 50
    @Flag(name: .long) var fixedSeed = false
    @Option(name: .long) var seed: UInt64?
    @Option(name: .long, help: "default | permissive") var guardrails: GuardrailsOption = .default
    @Option(name: .long) var session: String?
    @OptionGroup var global: GlobalOptions

    mutating func run() async throws {
        do {
            if global.dryRun {
                CLIPrinter.emit(payload: ["status": "dry_run", "command": "chat interactive"], human: "[dry-run] Interactive chat prepared.", global: global)
                return
            }

            try requireInteractiveTerminal(command: "fm chat interactive")
            var activeSessionPath = session
            var state = try loadSession(path: activeSessionPath)
            let model = createModel(guardrails: guardrails)
            let options = createChatGenerationOptions(
                sampling: sampling,
                topK: topK,
                fixedSeed: fixedSeed,
                seed: seed
            )

            CLIPrinter.emitHuman("Interactive mode started. Use /reset, /save <path>, /config, /exit.", global: global)

            while true {
                if !global.json && !global.quiet, let data = "fm> ".data(using: .utf8) {
                    FileHandle.standardOutput.write(data)
                }

                guard let line = readLine() else { break }
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }

                if trimmed == "/exit" { break }

                if trimmed == "/reset" {
                    state = .empty
                    try saveSession(state, path: activeSessionPath)
                    CLIPrinter.emitHuman("Session reset.", global: global)
                    continue
                }

                if trimmed == "/config" {
                    let payload: [String: Any] = [
                        "sampling": sampling.rawValue,
                        "topK": topK,
                        "fixedSeed": fixedSeed,
                        "seed": seed ?? 0,
                        "guardrails": guardrails.rawValue,
                        "sessionPath": activeSessionPath ?? ""
                    ]
                    CLIPrinter.emit(payload: payload, human: "Current config: \(payload)", global: global)
                    continue
                }

                if trimmed.hasPrefix("/save") {
                    let parts = trimmed.split(separator: " ", maxSplits: 1).map(String.init)
                    if parts.count == 2 {
                        activeSessionPath = parts[1]
                    }
                    try saveSession(state, path: activeSessionPath)
                    CLIPrinter.emitHuman("Session saved.", global: global)
                    continue
                }

                let prompt = chatPromptWithHistory(message: trimmed, history: state.messages)
                let response = try await runResponse(
                    prompt: prompt,
                    instructions: instructions,
                    model: model,
                    options: options,
                    global: global
                )

                state.messages.append(StoredMessage(role: "user", content: trimmed, timestamp: Date()))
                state.messages.append(StoredMessage(role: "assistant", content: response, timestamp: Date()))
                state.updatedAt = Date()
                try saveSession(state, path: activeSessionPath)
                CLIPrinter.emitHuman(response, global: global)
            }
        } catch {
            try fail(error, global: global)
        }
    }
}

struct ChatResetCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "reset",
        abstract: "Clear a persisted chat session."
    )
    @Option(name: .long) var session: String?
    @OptionGroup var global: GlobalOptions

    mutating func run() async throws {
        do {
            try resetSession(path: session)
            let payload: [String: Any] = [
                "status": "success",
                "message": "Session reset."
            ]
            CLIPrinter.emit(payload: payload, human: "Session reset.", global: global)
        } catch {
            try fail(error, global: global)
        }
    }
}

// MARK: - Examples

let exampleIDs: [String] = [
    "basic_chat",
    "journaling",
    "creative_writing",
    "structured_data",
    "streaming_response",
    "model_availability",
    "generation_guides",
    "generation_options",
    "health",
    "rag",
    "chat"
]

struct ExamplesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "examples",
        abstract: "Run curated examples that mirror app demos.",
        subcommands: [
            ExamplesListCommand.self,
            ExamplesRunCommand.self
        ]
    )
}

struct ExamplesListCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List available example IDs."
    )
    @OptionGroup var global: GlobalOptions

    mutating func run() async throws {
        CLIPrinter.emit(
            payload: ["examples": exampleIDs],
            human: exampleIDs.joined(separator: "\n"),
            global: global
        )
    }
}

struct ExamplesRunCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Run a specific example by ID."
    )

    @Argument(help: "Example ID from `examples list`.")
    var exampleID: String

    @Option(name: .long) var prompt: String?
    @Option(name: .long) var instructions: String?
    @Flag(name: .long) var stream = false
    @Option(name: .long) var temperature: Double = 0.7
    @Option(name: .long) var samplingMode: GenerationSamplingMode = .greedy
    @Option(name: .long) var topK: Int = 50
    @Option(name: .long) var topP: Double = 0.9
    @Option(name: .long) var maxResponseTokens: Int = 300
    @OptionGroup var global: GlobalOptions

    mutating func run() async throws {
        do {
            switch exampleID {
            case "basic_chat":
                try await runBasic()
            case "journaling":
                try await runJournaling()
            case "creative_writing":
                try await runCreative()
            case "structured_data":
                try await runStructured()
            case "streaming_response":
                try await runStreaming()
            case "model_availability":
                let snapshot = modelAvailabilitySnapshot()
                let payload: [String: Any] = [
                    "status": snapshot.status,
                    "reason": snapshot.reason ?? "",
                    "remediation": snapshot.remediation ?? ""
                ]
                CLIPrinter.emit(payload: payload, human: "\(snapshot.status)", global: global)
            case "generation_guides":
                try await runGuided()
            case "generation_options":
                try await runGenerationOptions()
            case "health":
                try await runHealthExample()
            case "rag":
                try await runRAGExample()
            case "chat":
                try await runBasic()
            default:
                throw CLICommandError.invalidInput("Unknown example id: \(exampleID)")
            }
        } catch {
            try fail(error, global: global)
        }
    }

    private func runBasic() async throws {
        let text = prompt ?? "Suggest a catchy name for a new coffee shop."
        let response = try await runResponse(
            prompt: text,
            instructions: instructions,
            model: SystemLanguageModel(useCase: .general),
            options: GenerationOptions(),
            global: global
        )
        CLIPrinter.emit(payload: ["example": exampleID, "response": response], human: response, global: global)
    }

    private func runJournaling() async throws {
        let text = prompt ?? """
        Mood: A bit anxious and overwhelmed by deadlines.
        Sleep: Restless, woke up twice.
        Entry: I kept jumping between tasks and felt guilty about not finishing.
        """
        if global.dryRun {
            CLIPrinter.emit(payload: ["status": "dry_run", "example": exampleID, "prompt": text], human: "[dry-run] Journaling request prepared.", global: global)
            return
        }

        let session = LanguageModelSession(
            instructions: Instructions("You are a gentle journaling coach.")
        )
        let response = try await withTimeout(seconds: global.timeout) {
            try await session.respond(to: Prompt(text), generating: JournalEntrySummary.self).content
        }

        let payload: [String: Any] = [
            "example": exampleID,
            "prompt": response.prompt,
            "upliftingMessage": response.upliftingMessage,
            "sentenceStarters": response.sentenceStarters,
            "summaryBullets": response.summaryBullets,
            "themes": response.themes
        ]
        CLIPrinter.emit(payload: payload, human: "\(response.upliftingMessage)\n\(response.prompt)", global: global)
    }

    private func runCreative() async throws {
        let text = prompt ?? "Write a story outline about time travel."
        if global.dryRun {
            CLIPrinter.emit(payload: ["status": "dry_run", "example": exampleID, "prompt": text], human: "[dry-run] Creative writing request prepared.", global: global)
            return
        }

        let session = if let instructions, !instructions.isEmpty {
            LanguageModelSession(instructions: Instructions(instructions))
        } else {
            LanguageModelSession()
        }

        let story = try await withTimeout(seconds: global.timeout) {
            try await session.respond(to: Prompt(text), generating: StoryOutline.self).content
        }

        let payload: [String: Any] = [
            "example": exampleID,
            "title": story.title,
            "protagonist": story.protagonist,
            "conflict": story.conflict,
            "setting": story.setting,
            "genre": String(describing: story.genre),
            "themes": story.themes
        ]
        CLIPrinter.emit(payload: payload, human: "\(story.title)\n\(story.conflict)", global: global)
    }

    private func runStructured() async throws {
        let text = prompt ?? "Suggest a sci-fi book."
        if global.dryRun {
            CLIPrinter.emit(payload: ["status": "dry_run", "example": exampleID, "prompt": text], human: "[dry-run] Structured generation request prepared.", global: global)
            return
        }

        let session = LanguageModelSession()
        let book = try await withTimeout(seconds: global.timeout) {
            try await session.respond(to: Prompt(text), generating: BookRecommendation.self).content
        }
        let payload: [String: Any] = [
            "example": exampleID,
            "title": book.title,
            "author": book.author,
            "description": book.description,
            "genre": String(describing: book.genre)
        ]
        CLIPrinter.emit(payload: payload, human: "\(book.title) by \(book.author)", global: global)
    }

    private func runStreaming() async throws {
        let text = prompt ?? "Write a short poem about nature."
        let result: String
        if stream {
            result = try await runStreamingResponse(
                prompt: text,
                instructions: instructions,
                model: SystemLanguageModel(useCase: .general),
                options: GenerationOptions(),
                global: global
            )
        } else {
            result = try await runResponse(
                prompt: text,
                instructions: instructions,
                model: SystemLanguageModel(useCase: .general),
                options: GenerationOptions(),
                global: global
            )
        }
        if global.json {
            CLIPrinter.emitJSON(["example": exampleID, "response": result])
        }
    }

    private func runGuided() async throws {
        let text = prompt ?? "Write a product review for a smartphone."
        if global.dryRun {
            CLIPrinter.emit(payload: ["status": "dry_run", "example": exampleID, "prompt": text], human: "[dry-run] Guided generation request prepared.", global: global)
            return
        }

        let session = LanguageModelSession()
        let review = try await withTimeout(seconds: global.timeout) {
            try await session.respond(to: Prompt(text), generating: ProductReview.self).content
        }

        let payload: [String: Any] = [
            "example": exampleID,
            "productName": review.productName,
            "rating": review.rating,
            "recommendation": review.recommendation,
            "pros": review.pros,
            "cons": review.cons,
            "reviewText": review.reviewText
        ]
        CLIPrinter.emit(payload: payload, human: "\(review.productName) (\(review.rating)/5)", global: global)
    }

    private func runGenerationOptions() async throws {
        let text = prompt ?? "Explain the difference between actors and classes in Swift."
        let sampling: GenerationOptions.SamplingMode = switch samplingMode {
        case .greedy:
            .greedy
        case .topK:
            .random(top: topK)
        case .topP:
            .random(probabilityThreshold: topP)
        }

        let options = GenerationOptions(
            sampling: sampling,
            temperature: temperature,
            maximumResponseTokens: maxResponseTokens
        )
        let response = try await runResponse(
            prompt: text,
            instructions: instructions,
            model: SystemLanguageModel(useCase: .general),
            options: options,
            global: global
        )
        CLIPrinter.emit(
            payload: [
                "example": exampleID,
                "samplingMode": samplingMode.rawValue,
                "temperature": temperature,
                "maxResponseTokens": maxResponseTokens,
                "response": response
            ],
            human: response,
            global: global
        )
    }

    private func runHealthExample() async throws {
        if global.dryRun {
            CLIPrinter.emit(
                payload: ["status": "dry_run", "example": exampleID, "query": prompt ?? "How many steps have I taken today?"],
                human: "[dry-run] Health example request prepared.",
                global: global
            )
            return
        }
        try requireCapability("health", status: healthCapability())
        let query = prompt ?? "How many steps have I taken today?"
        let response = try await runToolPrompt(
            tools: [HealthTool()],
            prompt: query,
            instructions: nil,
            global: global
        )
        CLIPrinter.emit(payload: ["example": exampleID, "response": response], human: response, global: global)
    }

    private func runRAGExample() async throws {
        if global.dryRun {
            CLIPrinter.emit(
                payload: ["status": "dry_run", "example": exampleID, "question": prompt ?? "What is Foundation Models?"],
                human: "[dry-run] RAG example request prepared.",
                global: global
            )
            return
        }
        let docs = try loadRAGDocuments()
        if docs.isEmpty {
            throw CLICommandError.invalidInput("RAG index is empty. Run `rag index-samples` or `rag index-text` first.")
        }
        let question = prompt ?? "What is Foundation Models?"
        let hits = searchRAG(query: question, documents: docs, limit: 2)
        guard !hits.isEmpty else {
            throw CLICommandError.invalidInput("No relevant RAG sources found for query.")
        }

        let sourcesText = hits.enumerated().map { idx, hit in
            "[\(idx + 1)] \(hit.document.title): \(hit.snippet)"
        }.joined(separator: "\n\n")
        let ragPrompt = """
        Use only the sources below. Cite with [1], [2].

        SOURCES:
        \(sourcesText)

        QUESTION:
        \(question)
        """

        let response = try await runResponse(
            prompt: ragPrompt,
            instructions: "You answer strictly from supplied sources.",
            model: SystemLanguageModel(useCase: .general),
            options: GenerationOptions(),
            global: global
        )
        CLIPrinter.emit(
            payload: [
                "example": exampleID,
                "question": question,
                "response": response
            ],
            human: response,
            global: global
        )
    }
}

// MARK: - Tools

let toolIDs: [String] = [
    "weather",
    "web-search",
    "contacts",
    "calendar",
    "reminders",
    "location",
    "health",
    "music",
    "web-metadata"
]

struct ToolsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tools",
        abstract: "Invoke integrated tools from the command line.",
        subcommands: [
            ToolsListCommand.self,
            ToolsWeatherCommand.self,
            ToolsWebSearchCommand.self,
            ToolsContactsCommand.self,
            ToolsCalendarCommand.self,
            ToolsRemindersCommand.self,
            ToolsLocationCommand.self,
            ToolsHealthCommand.self,
            ToolsMusicCommand.self,
            ToolsWebMetadataCommand.self
        ]
    )
}

struct ToolsListCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List tool IDs and availability."
    )
    @OptionGroup var global: GlobalOptions

    mutating func run() async throws {
        let payload: [String: Any] = [
            "tools": [
                "weather": ["available": true],
                "web-search": ["available": true],
                "web-metadata": ["available": true],
                "contacts": contactsCapability().payload,
                "calendar": calendarCapability().payload,
                "reminders": remindersCapability().payload,
                "location": locationCapability().payload,
                "health": healthCapability().payload,
                "music": await musicCapability().payload
            ]
        ]
        CLIPrinter.emit(payload: payload, human: toolIDs.joined(separator: "\n"), global: global)
    }
}

struct ToolsWeatherCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "weather",
        abstract: "Get weather by location."
    )
    @Option(name: .long) var location: String
    @OptionGroup var global: GlobalOptions

    mutating func run() async throws {
        do {
            let prompt = "What's the weather like in \(location)?"
            let response = try await runToolPrompt(
                tools: [WeatherTool()],
                prompt: prompt,
                instructions: nil,
                global: global
            )
            CLIPrinter.emit(payload: ["tool": "weather", "location": location, "response": response], human: response, global: global)
        } catch {
            try fail(error, global: global)
        }
    }
}

struct ToolsWebSearchCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "web-search",
        abstract: "Search the web using Search1 API."
    )
    @Option(name: .long) var query: String
    @Option(name: .long) var maxResults: Int = 5
    @OptionGroup var global: GlobalOptions

    mutating func run() async throws {
        do {
            let searchQuery = query
            let limit = maxResults

            guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw CLICommandError.invalidInput("Please provide --query.")
            }
            guard limit > 0 else {
                throw CLICommandError.invalidInput("--max-results must be greater than zero.")
            }

            if global.dryRun {
                CLIPrinter.emit(payload: ["status": "dry_run", "query": searchQuery, "maxResults": limit], human: "[dry-run] Web search prepared.", global: global)
                return
            }

            let results = try await withTimeout(seconds: global.timeout) {
                try await searchWeb(query: searchQuery, maxResults: limit)
            }
            let payloadResults = results.map { result in
                [
                    "title": result.title,
                    "link": result.link,
                    "snippet": result.snippet ?? result.content ?? ""
                ]
            }
            let human = results.enumerated().map { index, result in
                "\(index + 1). \(result.title)\n\(result.link)"
            }.joined(separator: "\n\n")

            CLIPrinter.emit(
                payload: [
                    "tool": "web-search",
                    "query": searchQuery,
                    "resultCount": results.count,
                    "results": payloadResults
                ],
                human: human.isEmpty ? "No results found." : human,
                global: global
            )
        } catch {
            try fail(error, global: global)
        }
    }
}

struct ToolsContactsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "contacts",
        abstract: "Search contacts."
    )
    @Option(name: .long) var query: String
    @OptionGroup var global: GlobalOptions

    mutating func run() async throws {
        do {
            if global.dryRun {
                CLIPrinter.emit(payload: ["status": "dry_run", "tool": "contacts", "query": query], human: "[dry-run] Contacts tool invocation prepared.", global: global)
                return
            }
            try requireCapability("contacts", status: contactsCapability())
            let response = try await runToolPrompt(
                tools: [ContactsTool()],
                prompt: "Find contacts named \(query)",
                instructions: nil,
                global: global
            )
            CLIPrinter.emit(payload: ["tool": "contacts", "query": query, "response": response], human: response, global: global)
        } catch {
            try fail(error, global: global)
        }
    }
}

struct ToolsCalendarCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "calendar",
        abstract: "Query calendar events."
    )
    @Option(name: .long) var query: String = "What events do I have today?"
    @OptionGroup var global: GlobalOptions

    mutating func run() async throws {
        do {
            if global.dryRun {
                CLIPrinter.emit(payload: ["status": "dry_run", "tool": "calendar", "query": query], human: "[dry-run] Calendar tool invocation prepared.", global: global)
                return
            }
            try requireCapability("calendar", status: calendarCapability())
            let formatter = ISO8601DateFormatter()
            formatter.timeZone = .current
            let prompt = """
            The user's current time zone is \(TimeZone.current.identifier).
            The user's current locale identifier is \(Locale.current.identifier).
            The current local date and time is \(formatter.string(from: Date())).
            Use this context when interpreting relative dates.

            \(query)
            """
            let response = try await runToolPrompt(
                tools: [CalendarTool()],
                prompt: prompt,
                instructions: nil,
                global: global
            )
            CLIPrinter.emit(payload: ["tool": "calendar", "query": query, "response": response], human: response, global: global)
        } catch {
            try fail(error, global: global)
        }
    }
}

struct ToolsRemindersCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "reminders",
        abstract: "Create reminders via quick fields or custom prompt."
    )
    @Option(name: .long) var title: String?
    @Option(name: .long) var notes: String = ""
    @Option(name: .long) var dueDate: String?
    @Option(name: .long) var priority: ReminderPriorityOption = .none
    @Option(name: .long) var prompt: String?
    @OptionGroup var global: GlobalOptions

    mutating func run() async throws {
        do {
            if global.dryRun {
                CLIPrinter.emit(payload: ["status": "dry_run", "tool": "reminders"], human: "[dry-run] Reminders tool invocation prepared.", global: global)
                return
            }
            try requireCapability("reminders", status: remindersCapability())
            let now = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

            let instructions = """
            You are a helpful assistant that creates reminders.
            Current date and time: \(formatter.string(from: now))
            Time zone: \(TimeZone.current.identifier)
            Always execute the RemindersTool directly.
            Due dates must be formatted as yyyy-MM-dd HH:mm:ss.
            """

            let finalPrompt: String
            if let prompt, !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                finalPrompt = prompt
            } else {
                guard let title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw CLICommandError.invalidInput("Provide --prompt or --title.")
                }
                var text = "Create a reminder with the following details:\nTitle: \(title)\n"
                if !notes.isEmpty { text += "Notes: \(notes)\n" }
                if let dueDate, !dueDate.isEmpty { text += "Due date: \(dueDate)\n" }
                if priority != .none { text += "Priority: \(priority.rawValue)\n" }
                finalPrompt = text
            }

            let response = try await runToolPrompt(
                tools: [RemindersTool()],
                prompt: finalPrompt,
                instructions: instructions,
                global: global
            )
            CLIPrinter.emit(payload: ["tool": "reminders", "response": response], human: response, global: global)
        } catch {
            try fail(error, global: global)
        }
    }
}

struct ToolsLocationCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "location",
        abstract: "Retrieve current location summary."
    )
    @OptionGroup var global: GlobalOptions

    mutating func run() async throws {
        do {
            if global.dryRun {
                CLIPrinter.emit(payload: ["status": "dry_run", "tool": "location"], human: "[dry-run] Location tool invocation prepared.", global: global)
                return
            }
            try requireCapability("location", status: locationCapability())
            let response = try await runToolPrompt(
                tools: [LocationTool()],
                prompt: "What's my current location?",
                instructions: nil,
                global: global
            )
            CLIPrinter.emit(payload: ["tool": "location", "response": response], human: response, global: global)
        } catch {
            try fail(error, global: global)
        }
    }
}

struct ToolsHealthCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "health",
        abstract: "Query health data via tool prompts."
    )
    @Option(name: .long) var query: String = "How many steps have I taken today?"
    @OptionGroup var global: GlobalOptions

    mutating func run() async throws {
        do {
            if global.dryRun {
                CLIPrinter.emit(payload: ["status": "dry_run", "tool": "health", "query": query], human: "[dry-run] Health tool invocation prepared.", global: global)
                return
            }
            try requireCapability("health", status: healthCapability())
            let today = Date()
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: today) ?? today
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = .current
            let todayString = dateFormatter.string(from: today)
            let yesterdayString = dateFormatter.string(from: yesterday)
            let weekAgoString = dateFormatter.string(from: weekAgo)

            let prompt = """
            \(query)

            Today's date is: \(todayString)
            Use Health tool arguments with these rules:
            - today => \(todayString) to \(todayString)
            - yesterday => \(yesterdayString) to \(yesterdayString)
            - this week/default => \(weekAgoString) to \(todayString)
            """

            let response = try await runToolPrompt(
                tools: [HealthTool()],
                prompt: prompt,
                instructions: nil,
                global: global
            )
            CLIPrinter.emit(payload: ["tool": "health", "query": query, "response": response], human: response, global: global)
        } catch {
            try fail(error, global: global)
        }
    }
}

struct ToolsMusicCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "music",
        abstract: "Search music with authorization checks."
    )
    @Option(name: .long) var query: String
    @OptionGroup var global: GlobalOptions

    mutating func run() async throws {
        do {
            if global.dryRun {
                CLIPrinter.emit(payload: ["status": "dry_run", "tool": "music", "query": query], human: "[dry-run] Music tool invocation prepared.", global: global)
                return
            }
            let capability = await musicCapability()
            try requireCapability("music", status: capability)
            let response = try await runToolPrompt(
                tools: [MusicTool()],
                prompt: query,
                instructions: nil,
                global: global
            )
            CLIPrinter.emit(payload: ["tool": "music", "query": query, "response": response], human: response, global: global)
        } catch {
            try fail(error, global: global)
        }
    }
}

struct ToolsWebMetadataCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "web-metadata",
        abstract: "Fetch and summarize web metadata."
    )
    @Option(name: .long) var url: String
    @OptionGroup var global: GlobalOptions

    mutating func run() async throws {
        do {
            guard let parsedURL = URL(string: url),
                  let scheme = parsedURL.scheme?.lowercased(),
                  ["http", "https"].contains(scheme),
                  parsedURL.host != nil else {
                throw CLICommandError.invalidInput("Provide a valid --url with http/https scheme.")
            }

            let response = try await runToolPrompt(
                tools: [WebMetadataTool()],
                prompt: "Generate a social media summary for \(url)",
                instructions: nil,
                global: global
            )
            CLIPrinter.emit(payload: ["tool": "web-metadata", "url": url, "response": response], human: response, global: global)
        } catch {
            try fail(error, global: global)
        }
    }
}

// MARK: - Schemas

let schemaIDs: [String] = [
    "basic_object",
    "array_schema",
    "enum_schema",
    "nested_objects",
    "schema_references",
    "generation_guides",
    "generable_pattern",
    "union_types",
    "form_builder",
    "error_handling",
    "invoice_processing"
]

struct SchemasCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "schemas",
        abstract: "Run dynamic schema generation examples.",
        subcommands: [
            SchemasListCommand.self,
            SchemasRunCommand.self
        ]
    )
}

struct SchemasListCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List schema IDs."
    )
    @OptionGroup var global: GlobalOptions

    mutating func run() async throws {
        CLIPrinter.emit(payload: ["schemas": schemaIDs], human: schemaIDs.joined(separator: "\n"), global: global)
    }
}

struct SchemasRunCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Run a schema by ID."
    )

    @Argument var schemaID: String
    @Option(name: .long) var input: String?
    @Option(name: .long) var inputFile: String?
    @Flag(name: .long) var pretty = false
    @Option(name: .long) var minItems: Int?
    @Option(name: .long) var maxItems: Int?
    @Option(name: .long) var customChoices: String?
    @Option(name: .long) var nestingDepth: Int = 1
    @Option(name: .long) var mode: String = "default"
    @Flag(name: .long) var includeValidation = false
    @Flag(name: .long) var includeLineItems = false
    @Flag(name: .long) var calculateTotals = false
    @Option(name: .long) var scenario: String = "default"
    @Flag(name: .long) var detailed = false
    @OptionGroup var global: GlobalOptions

    mutating func run() async throws {
        do {
            guard schemaIDs.contains(schemaID) else {
                throw CLICommandError.invalidInput("Unknown schema id: \(schemaID)")
            }

            let inputText = try resolvedInputText()
            if schemaID == "generable_pattern" {
                try await runGenerablePattern(inputText: inputText)
                return
            }

            let (schema, promptText) = try buildSchemaAndPrompt(inputText: inputText)
            if global.dryRun {
                CLIPrinter.emit(
                    payload: ["status": "dry_run", "schemaId": schemaID, "prompt": promptText],
                    human: "[dry-run] Schema request prepared.",
                    global: global
                )
                return
            }

            let session = LanguageModelSession()
            let generationSchema = try GenerationSchema(root: schema, dependencies: [])
            let output = try await withTimeout(seconds: global.timeout) {
                try await session.respond(to: Prompt(promptText), schema: generationSchema)
            }

            let object = try generatedObject(from: output.content)
            let jsonText = formattedJSONString(from: object, pretty: pretty || global.json)
            let payload: [String: Any] = [
                "schemaId": schemaID,
                "output": object
            ]
            CLIPrinter.emit(payload: payload, human: jsonText, global: global)
        } catch {
            try fail(error, global: global)
        }
    }

    private func resolvedInputText() throws -> String {
        if let inputFile, !inputFile.isEmpty {
            let filePath = expandedPath(inputFile)
            return try String(contentsOfFile: filePath, encoding: .utf8)
        }
        if let input, !input.isEmpty {
            return input
        }
        return "Generate realistic sample data."
    }

    private func runGenerablePattern(inputText: String) async throws {
        if global.dryRun {
            CLIPrinter.emit(
                payload: ["status": "dry_run", "schemaId": schemaID, "input": inputText],
                human: "[dry-run] Generable pattern request prepared.",
                global: global
            )
            return
        }
        let session = LanguageModelSession()
        let response = try await withTimeout(seconds: global.timeout) {
            try await session.respond(to: Prompt(inputText), generating: BookRecommendation.self).content
        }
        let payload: [String: Any] = [
            "schemaId": schemaID,
            "title": response.title,
            "author": response.author,
            "description": response.description,
            "genre": String(describing: response.genre)
        ]
        CLIPrinter.emit(payload: payload, human: "\(response.title) by \(response.author)", global: global)
    }

    private func buildSchemaAndPrompt(inputText: String) throws -> (DynamicGenerationSchema, String) {
        switch schemaID {
        case "basic_object":
            let schema = DynamicGenerationSchema(
                name: "BasicObject",
                description: "A simple object",
                properties: [
                    typedProperty("name", type: String.self),
                    typedProperty("category", type: String.self),
                    typedProperty("priority", type: Int.self)
                ]
            )
            return (schema, inputText)
        case "array_schema":
            let itemSchema = DynamicGenerationSchema(type: String.self)
            let schema = DynamicGenerationSchema(
                name: "ArraySchema",
                description: "Array output schema",
                properties: [
                    dynamicProperty(
                        name: "items",
                        schema: DynamicGenerationSchema(
                            arrayOf: itemSchema,
                            minimumElements: minItems,
                            maximumElements: maxItems
                        )
                    )
                ]
            )
            return (schema, inputText)
        case "enum_schema":
            let choices = customChoices ?? "low,medium,high"
            let schema = DynamicGenerationSchema(
                name: "EnumSchema",
                properties: [
                    typedProperty("choice", type: String.self),
                    typedProperty("reason", type: String.self)
                ]
            )
            return (schema, "\(inputText)\nAllowed choices: \(choices)")
        case "nested_objects":
            let addressSchema = DynamicGenerationSchema(
                name: "Address",
                properties: [
                    typedProperty("street", type: String.self),
                    typedProperty("city", type: String.self),
                    typedProperty("country", type: String.self)
                ]
            )
            let schema = DynamicGenerationSchema(
                name: "NestedSchema",
                properties: [
                    typedProperty("name", type: String.self),
                    dynamicProperty(name: "address", schema: addressSchema),
                    typedProperty("depth", type: Int.self)
                ]
            )
            return (schema, "\(inputText)\nTarget nesting depth: \(nestingDepth)")
        case "schema_references":
            let schema = DynamicGenerationSchema(
                name: "ReferenceLikeSchema",
                properties: [
                    typedProperty("id", type: String.self),
                    typedProperty("owner", type: String.self),
                    typedProperty("relatedItems", type: [String].self)
                ]
            )
            return (schema, inputText)
        case "generation_guides":
            let schema = DynamicGenerationSchema(
                name: "GuidedSchema",
                properties: [
                    typedProperty("title", type: String.self),
                    typedProperty("score", type: Int.self),
                    typedProperty("summary", type: String.self)
                ]
            )
            return (schema, inputText)
        case "union_types":
            let schema = DynamicGenerationSchema(
                name: "UnionLikeSchema",
                properties: [
                    typedProperty("valueType", type: String.self),
                    typedProperty("value", type: String.self)
                ]
            )
            return (schema, inputText)
        case "form_builder":
            let fieldSchema = DynamicGenerationSchema(
                name: "FormField",
                properties: [
                    typedProperty("label", type: String.self),
                    typedProperty("type", type: String.self),
                    typedProperty("required", type: Bool.self)
                ]
            )
            let schema = DynamicGenerationSchema(
                name: "FormSchema",
                properties: [
                    typedProperty("formTitle", type: String.self),
                    dynamicProperty(
                        name: "fields",
                        schema: DynamicGenerationSchema(
                            arrayOf: fieldSchema,
                            minimumElements: minItems,
                            maximumElements: maxItems
                        )
                    ),
                    typedProperty("mode", type: String.self),
                    typedProperty("includeValidation", type: Bool.self)
                ]
            )
            return (schema, "\(inputText)\nmode=\(mode), includeValidation=\(includeValidation)")
        case "error_handling":
            let schema = DynamicGenerationSchema(
                name: "ErrorHandlingSchema",
                properties: [
                    typedProperty("scenario", type: String.self),
                    typedProperty("status", type: String.self),
                    typedProperty("recoverySteps", type: [String].self),
                    typedProperty("detailed", type: Bool.self)
                ]
            )
            return (schema, "\(inputText)\nscenario=\(scenario), detailed=\(detailed)")
        case "invoice_processing":
            let lineItem = DynamicGenerationSchema(
                name: "LineItem",
                properties: [
                    typedProperty("description", type: String.self),
                    typedProperty("quantity", type: Int.self),
                    typedProperty("unitPrice", type: Double.self)
                ]
            )
            let schema = DynamicGenerationSchema(
                name: "InvoiceSchema",
                properties: [
                    typedProperty("invoiceNumber", type: String.self),
                    typedProperty("vendor", type: String.self),
                    typedProperty("subtotal", type: Double.self),
                    typedProperty("tax", type: Double.self),
                    typedProperty("total", type: Double.self),
                    dynamicProperty(
                        name: "lineItems",
                        schema: DynamicGenerationSchema(
                            arrayOf: lineItem,
                            minimumElements: includeLineItems ? 1 : 0,
                            maximumElements: maxItems
                        )
                    )
                ]
            )
            return (schema, "\(inputText)\ncalculateTotals=\(calculateTotals), mode=\(mode)")
        default:
            throw CLICommandError.invalidInput("Unsupported schema: \(schemaID)")
        }
    }
}

// MARK: - Languages

struct LanguagesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "languages",
        abstract: "Run language and multilingual demos.",
        subcommands: [
            LanguagesListSupportedCommand.self,
            LanguagesMultilingualPlayCommand.self,
            LanguagesSessionDemoCommand.self,
            LanguagesAnalyzeNutritionCommand.self
        ]
    )
}

struct LanguagesListSupportedCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list-supported",
        abstract: "List model-supported languages."
    )
    @OptionGroup var global: GlobalOptions

    mutating func run() async throws {
        let languages = Array(SystemLanguageModel.default.supportedLanguages).map { language -> [String: String] in
            let code = language.languageCode?.identifier ?? ""
            let region = language.region?.identifier ?? ""
            let localized = Locale.current.localizedString(forLanguageCode: code) ?? code
            let displayName = region.isEmpty ? localized : "\(localized) (\(code)-\(region))"
            return [
                "code": code,
                "region": region,
                "displayName": displayName
            ]
        }.sorted { lhs, rhs in
            (lhs["displayName"] ?? "") < (rhs["displayName"] ?? "")
        }

        let human = languages.map { $0["displayName"] ?? "" }.joined(separator: "\n")
        CLIPrinter.emit(payload: ["languages": languages], human: human, global: global)
    }
}

struct LanguagesMultilingualPlayCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "multilingual-play",
        abstract: "Run multilingual prompt set."
    )
    @OptionGroup var global: GlobalOptions

    mutating func run() async throws {
        let prompts: [(String, String)] = [
            ("English", "What is the capital of France?"),
            ("Spanish", "¿Cuál es la capital de España?"),
            ("French", "Quelle est la capitale de l'Allemagne ?"),
            ("German", "Was ist die Hauptstadt von Italien?")
        ]

        if global.dryRun {
            CLIPrinter.emit(payload: ["status": "dry_run", "prompts": prompts.map { ["language": $0.0, "prompt": $0.1] }], human: "[dry-run] Multilingual run prepared.", global: global)
            return
        }

        let session = LanguageModelSession(model: SystemLanguageModel.default)
        var results: [[String: String]] = []
        for (language, prompt) in prompts {
            do {
                let response = try await withTimeout(seconds: global.timeout) {
                    try await session.respond(to: Prompt(prompt)).content
                }
                results.append(["language": language, "prompt": prompt, "response": response, "status": "success"])
            } catch {
                results.append(["language": language, "prompt": prompt, "response": error.localizedDescription, "status": "error"])
            }
        }

        let human = results.map { row in
            "\(row["language"] ?? ""): \(row["response"] ?? "")"
        }.joined(separator: "\n\n")
        CLIPrinter.emit(payload: ["results": results], human: human, global: global)
    }
}

struct LanguagesSessionDemoCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "session-demo",
        abstract: "Run a mixed-language session context demo."
    )
    @OptionGroup var global: GlobalOptions

    mutating func run() async throws {
        do {
            let steps = [
                "Hello, how are you?",
                "Hola, ¿cómo estás?",
                "Now answer in English please.",
                "What language did I first speak to you in?"
            ]

            if global.dryRun {
                CLIPrinter.emit(payload: ["status": "dry_run", "steps": steps], human: "[dry-run] Session demo prepared.", global: global)
                return
            }

            let session = LanguageModelSession(
                model: SystemLanguageModel.default,
                instructions: Instructions("You are a multilingual assistant and keep conversation context across languages.")
            )
            var results: [[String: String]] = []
            for prompt in steps {
                let response = try await withTimeout(seconds: global.timeout) {
                    try await session.respond(to: Prompt(prompt)).content
                }
                results.append(["prompt": prompt, "response": response])
            }

            let human = results.map { "Q: \($0["prompt"] ?? "")\nA: \($0["response"] ?? "")" }.joined(separator: "\n\n")
            CLIPrinter.emit(payload: ["steps": results], human: human, global: global)
        } catch {
            try fail(error, global: global)
        }
    }
}

struct LanguagesAnalyzeNutritionCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "analyze-nutrition",
        abstract: "Analyze meal nutrition with localized response."
    )

    @Option(name: .long) var description: String
    @Option(name: .long) var language: String = "English"
    @OptionGroup var global: GlobalOptions

    mutating func run() async throws {
        do {
            guard !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw CLICommandError.invalidInput("Please provide --description.")
            }

            if global.dryRun {
                CLIPrinter.emit(
                    payload: ["status": "dry_run", "description": description, "language": language],
                    human: "[dry-run] Nutrition analysis request prepared.",
                    global: global
                )
                return
            }

            let instructions = """
            You are a nutrition expert.
            Respond in \(language).
            Estimate practical portions and provide concise output.
            """

            let parsePrompt = """
            Respond in \(language). Parse this food description into structured nutrition values:
            \(description)
            """

            let session = LanguageModelSession(instructions: Instructions(instructions))
            let parsed = try await withTimeout(seconds: global.timeout) {
                try await session.respond(to: Prompt(parsePrompt), generating: NutritionParseResult.self).content
            }
            let insightPrompt = """
            Respond in \(language). Give 2-3 supportive sentences about:
            \(parsed.foodName), \(parsed.calories) calories, \(parsed.proteinGrams)g protein, \(parsed.carbsGrams)g carbs, \(parsed.fatGrams)g fat.
            """
            let insights = try await withTimeout(seconds: global.timeout) {
                try await session.respond(to: Prompt(insightPrompt)).content
            }

            let payload: [String: Any] = [
                "foodName": parsed.foodName,
                "calories": parsed.calories,
                "proteinGrams": parsed.proteinGrams,
                "carbsGrams": parsed.carbsGrams,
                "fatGrams": parsed.fatGrams,
                "insights": insights
            ]
            let human = """
            \(parsed.foodName): \(parsed.calories) kcal
            Protein \(parsed.proteinGrams)g | Carbs \(parsed.carbsGrams)g | Fat \(parsed.fatGrams)g

            \(insights)
            """
            CLIPrinter.emit(payload: payload, human: human, global: global)
        } catch {
            try fail(error, global: global)
        }
    }
}

// MARK: - RAG

struct RagCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "rag",
        abstract: "Index/search local documents and answer with citations.",
        subcommands: [
            RagStatusCommand.self,
            RagIndexFileCommand.self,
            RagIndexTextCommand.self,
            RagIndexSamplesCommand.self,
            RagSearchCommand.self,
            RagAskCommand.self,
            RagResetCommand.self
        ]
    )
}

struct RagStatusCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "status",
        abstract: "Show RAG index status."
    )
    @OptionGroup var global: GlobalOptions

    mutating func run() async throws {
        do {
            let docs = try loadRAGDocuments()
            let payload: [String: Any] = [
                "documentCount": docs.count,
                "storagePath": ragStorageURL.path
            ]
            let human = "Indexed documents: \(docs.count)\nStore: \(ragStorageURL.path)"
            CLIPrinter.emit(payload: payload, human: human, global: global)
        } catch {
            try fail(error, global: global)
        }
    }
}

struct RagIndexFileCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "index-file",
        abstract: "Index a text-based file."
    )
    @Option(name: .long) var path: String
    @OptionGroup var global: GlobalOptions

    mutating func run() async throws {
        do {
            let filePath = expandedPath(path)
            let content = try String(contentsOfFile: filePath, encoding: .utf8)
            var docs = try loadRAGDocuments()
            let doc = RAGDocument(
                id: UUID(),
                title: URL(fileURLWithPath: filePath).lastPathComponent,
                content: content,
                sourceType: "file",
                source: filePath,
                indexedAt: Date()
            )
            docs.append(doc)
            try saveRAGDocuments(docs)
            CLIPrinter.emit(
                payload: ["status": "success", "indexedId": doc.id.uuidString, "title": doc.title],
                human: "Indexed file: \(doc.title)",
                global: global
            )
        } catch {
            try fail(error, global: global)
        }
    }
}

struct RagIndexTextCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "index-text",
        abstract: "Index arbitrary text."
    )
    @Option(name: .long) var title: String
    @Option(name: .long) var text: String
    @OptionGroup var global: GlobalOptions

    mutating func run() async throws {
        do {
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw CLICommandError.invalidInput("Please provide non-empty --text.")
            }

            var docs = try loadRAGDocuments()
            let doc = RAGDocument(
                id: UUID(),
                title: title,
                content: text,
                sourceType: "text",
                source: "inline",
                indexedAt: Date()
            )
            docs.append(doc)
            try saveRAGDocuments(docs)
            CLIPrinter.emit(
                payload: ["status": "success", "indexedId": doc.id.uuidString, "title": title],
                human: "Indexed text: \(title)",
                global: global
            )
        } catch {
            try fail(error, global: global)
        }
    }
}

struct RagIndexSamplesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "index-samples",
        abstract: "Load built-in sample documents."
    )
    @OptionGroup var global: GlobalOptions

    mutating func run() async throws {
        do {
            var docs = try loadRAGDocuments()
            let existingTitles = Set(docs.map(\.title))
            var indexed = 0
            for sample in ragSampleDocuments where !existingTitles.contains(sample.title) {
                docs.append(
                    RAGDocument(
                        id: UUID(),
                        title: sample.title,
                        content: sample.text,
                        sourceType: "sample",
                        source: "builtin",
                        indexedAt: Date()
                    )
                )
                indexed += 1
            }
            try saveRAGDocuments(docs)
            CLIPrinter.emit(
                payload: ["status": "success", "indexedSamples": indexed, "totalDocuments": docs.count],
                human: "Indexed \(indexed) sample document(s).",
                global: global
            )
        } catch {
            try fail(error, global: global)
        }
    }
}

struct RagSearchCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "search",
        abstract: "Search indexed documents."
    )
    @Option(name: .long) var query: String
    @OptionGroup var global: GlobalOptions

    mutating func run() async throws {
        do {
            let docs = try loadRAGDocuments()
            let hits = searchRAG(query: query, documents: docs, limit: 5)
            let payloadHits = hits.map { hit in
                [
                    "id": hit.document.id.uuidString,
                    "title": hit.document.title,
                    "score": hit.score,
                    "snippet": hit.snippet
                ] as [String: Any]
            }
            let human = hits.enumerated().map { idx, hit in
                "\(idx + 1). \(hit.document.title) (\(String(format: "%.2f", hit.score)))\n\(hit.snippet)"
            }.joined(separator: "\n\n")

            CLIPrinter.emit(
                payload: ["query": query, "resultCount": hits.count, "results": payloadHits],
                human: human.isEmpty ? "No results found." : human,
                global: global
            )
        } catch {
            try fail(error, global: global)
        }
    }
}

struct RagAskCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ask",
        abstract: "Answer a question with source citations."
    )
    @Option(name: .long) var question: String
    @OptionGroup var global: GlobalOptions

    mutating func run() async throws {
        do {
            let docs = try loadRAGDocuments()
            guard !docs.isEmpty else {
                throw CLICommandError.invalidInput("RAG index is empty. Index documents first.")
            }

            let hits = searchRAG(query: question, documents: docs, limit: 3)
            guard !hits.isEmpty else {
                throw CLICommandError.invalidInput("No relevant sources found for this question.")
            }

            let citations = hits.enumerated().map { index, hit in
                [
                    "id": index + 1,
                    "title": hit.document.title,
                    "documentId": hit.document.id.uuidString
                ] as [String: Any]
            }
            let sourcesText = hits.enumerated().map { index, hit in
                "[\(index + 1)] \(hit.document.title)\n\(hit.snippet)"
            }.joined(separator: "\n\n")
            let ragPrompt = """
            You are a retrieval assistant.
            Use only the provided sources and cite claims with [1], [2], [3].
            If the answer is missing, say you do not know.

            SOURCES:
            \(sourcesText)

            QUESTION:
            \(question)
            """

            let response = try await runResponse(
                prompt: ragPrompt,
                instructions: "Answer strictly from sources.",
                model: SystemLanguageModel(useCase: .general),
                options: GenerationOptions(),
                global: global
            )

            CLIPrinter.emit(
                payload: [
                    "question": question,
                    "answer": response,
                    "citations": citations
                ],
                human: "\(response)\n\nSources:\n\(citations.map { "[\($0["id"]!)] \($0["title"]!)" }.joined(separator: "\n"))",
                global: global
            )
        } catch {
            try fail(error, global: global)
        }
    }
}

struct RagResetCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "reset",
        abstract: "Reset the RAG index."
    )
    @OptionGroup var global: GlobalOptions

    mutating func run() async throws {
        do {
            try saveRAGDocuments([])
            CLIPrinter.emit(payload: ["status": "success"], human: "RAG index reset.", global: global)
        } catch {
            try fail(error, global: global)
        }
    }
}

// MARK: - Health Group

struct HealthCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "health",
        abstract: "Health-focused commands.",
        subcommands: [
            HealthFetchCommand.self,
            HealthAnalyzeCommand.self,
            HealthChatCommand.self
        ]
    )
}

struct HealthFetchCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "fetch",
        abstract: "Fetch health data using Health tool semantics."
    )
    @Option(name: .long) var dataType: String = "today"
    @Flag(name: .long) var refresh = false
    @OptionGroup var global: GlobalOptions

    mutating func run() async throws {
        do {
            if global.dryRun {
                CLIPrinter.emit(payload: ["status": "dry_run", "dataType": dataType, "refresh": refresh], human: "[dry-run] Health fetch prepared.", global: global)
                return
            }
            try requireCapability("health", status: healthCapability())
            let prompt = """
            Use the Health tool to fetch \(dataType) data.
            refreshFromHealthKit should be \(refresh).
            """
            let response = try await runToolPrompt(
                tools: [HealthTool()],
                prompt: prompt,
                instructions: nil,
                global: global
            )
            CLIPrinter.emit(
                payload: ["dataType": dataType, "refresh": refresh, "response": response],
                human: response,
                global: global
            )
        } catch {
            try fail(error, global: global)
        }
    }
}

struct HealthAnalyzeCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "analyze",
        abstract: "Run analysis over health metrics."
    )
    @Option(name: .long) var analysisType: String = "daily"
    @Option(name: .long) var days: Int = 7
    @Option(name: .long) var focusMetrics: String?
    @Flag(name: .long) var includePredictions = false
    @OptionGroup var global: GlobalOptions

    mutating func run() async throws {
        do {
            let prompt = """
            Analyze health metrics with:
            analysisType=\(analysisType)
            daysToAnalyze=\(days)
            focusMetrics=\(focusMetrics ?? "")
            includePredictions=\(includePredictions)
            """
            let response = try await runToolPrompt(
                tools: [HealthAnalysisTool()],
                prompt: prompt,
                instructions: nil,
                global: global
            )
            CLIPrinter.emit(
                payload: [
                    "analysisType": analysisType,
                    "days": days,
                    "focusMetrics": focusMetrics ?? "",
                    "includePredictions": includePredictions,
                    "response": response
                ],
                human: response,
                global: global
            )
        } catch {
            try fail(error, global: global)
        }
    }
}

struct HealthChatCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "chat",
        abstract: "Interactive health assistant chat."
    )
    @Option(name: .long) var session: String?
    @OptionGroup var global: GlobalOptions

    mutating func run() async throws {
        do {
            if global.dryRun {
                CLIPrinter.emit(payload: ["status": "dry_run", "command": "health chat"], human: "[dry-run] Health chat prepared.", global: global)
                return
            }
            try requireInteractiveTerminal(command: "fm health chat")
            try requireCapability("health", status: healthCapability())
            var state = try loadSession(path: session)
            CLIPrinter.emitHuman("Health chat started. Type /exit to quit, /reset to clear.", global: global)

            while true {
                if !global.json && !global.quiet, let data = "health> ".data(using: .utf8) {
                    FileHandle.standardOutput.write(data)
                }
                guard let line = readLine() else { break }
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }

                if trimmed == "/exit" { break }
                if trimmed == "/reset" {
                    state = .empty
                    try saveSession(state, path: session)
                    CLIPrinter.emitHuman("Health chat session reset.", global: global)
                    continue
                }

                let prompt = chatPromptWithHistory(message: trimmed, history: state.messages)
                let response = try await runToolPrompt(
                    tools: [HealthTool(), HealthAnalysisTool()],
                    prompt: prompt,
                    instructions: "You are a supportive health coach.",
                    global: global
                )
                state.messages.append(StoredMessage(role: "user", content: trimmed, timestamp: Date()))
                state.messages.append(StoredMessage(role: "assistant", content: response, timestamp: Date()))
                state.updatedAt = Date()
                try saveSession(state, path: session)
                CLIPrinter.emitHuman(response, global: global)
            }
        } catch {
            try fail(error, global: global)
        }
    }
}

// MARK: - Voice

struct VoiceCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "voice",
        abstract: "Voice capability checks.",
        subcommands: [VoiceCheckCommand.self]
    )
}

struct VoiceCheckCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "check",
        abstract: "Check speech and microphone readiness."
    )
    @OptionGroup var global: GlobalOptions

    mutating func run() async throws {
        let speech = speechCapability()
        let mic = microphoneCapability()
        let payload: [String: Any] = [
            "speechRecognition": speech.payload,
            "microphone": mic.payload,
            "synthesisReady": true
        ]
        let human = """
        Speech recognition: \(speech.available ? "ready" : "unavailable")
        Microphone: \(mic.available ? "ready" : "unavailable")
        Synthesis: ready
        """
        CLIPrinter.emit(payload: payload, human: human, global: global)
    }
}

if #available(macOS 10.15, macCatalyst 13, iOS 13, tvOS 13, watchOS 6, *) {
    let semaphore = DispatchSemaphore(value: 0)
    Task {
        await FoundationLabCLI.main()
        semaphore.signal()
    }
    semaphore.wait()
} else {
    fputs("FoundationLabCLI requires a newer operating system.\n", stderr)
    exit(1)
}
