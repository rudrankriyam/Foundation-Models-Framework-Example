import ArgumentParser
import Foundation
import FoundationModels

struct DryRunPayload: Encodable {
    let status: String = "dry_run"
    let command: String
    let prompt: String?
    let messages: [String]?
    let preset: String?
    let file: String?
    let input: String?

    init(
        command: String,
        prompt: String? = nil,
        messages: [String]? = nil,
        preset: String? = nil,
        file: String? = nil,
        input: String? = nil
    ) {
        self.command = command
        self.prompt = prompt
        self.messages = messages
        self.preset = preset
        self.file = file
        self.input = input
    }
}

struct CLITranscriptEntry: Encodable, Hashable {
    let role: String
    let content: String
}

struct GlobalCommandOptions: ParsableArguments {
    @Option(name: .long, help: "Output format. Defaults to text in terminals and json in pipes/CI.")
    var output: CLIOutputFormat?

    @Flag(name: .long, help: "Pretty-print JSON output.")
    var pretty = false

    @Flag(name: .long, help: "Include execution metadata in human-readable output.")
    var verbose = false

    @Flag(name: .customLong("dry-run"), help: "Print the request shape without executing it.")
    var dryRun = false

    func resolvedOutput() throws -> CLIOutputOptions {
        try CLIOutput.resolve(output: output, pretty: pretty)
    }
}

enum CLISamplingMode: String, CaseIterable, ExpressibleByArgument {
    case greedy
    case topK = "top-k"
    case nucleus
}

enum CLIFeedbackSentiment: String, CaseIterable, ExpressibleByArgument {
    case positive
    case negative
    case neutral

    var foundationModelsValue: LanguageModelFeedback.Sentiment {
        switch self {
        case .positive:
            .positive
        case .negative:
            .negative
        case .neutral:
            .neutral
        }
    }
}

struct GenerationFlags: ParsableArguments {
    @Option(name: .long, help: "Optional system instructions for the request.")
    var systemPrompt: String?

    @Option(name: .long, help: "Sampling mode: greedy, top-k, or nucleus.")
    var sampling: CLISamplingMode?

    @Option(name: .customLong("top-k"), help: "Top-k value when using --sampling top-k.")
    var topK: Int?

    @Option(name: .customLong("top-p"), help: "Probability threshold when using --sampling nucleus.")
    var topP: Double?

    @Option(name: .long, help: "Optional random seed for non-greedy sampling.")
    var seed: UInt64?

    @Option(name: .long, help: "Sampling temperature between 0 and 1.")
    var temperature: Double?

    @Option(name: .customLong("max-tokens"), help: "Maximum number of response tokens.")
    var maxTokens: Int?

    @Option(name: .long, help: "Guardrails mode.")
    var guardrails: AFMGuardrails = .default

    func validatedOptions() throws -> AFMGenerationOptions? {
        if seed != nil && sampling != .topK && sampling != .nucleus {
            throw ValidationError("--seed is only valid with non-greedy sampling")
        }
        if let temperature, !(0...1).contains(temperature) {
            throw ValidationError("--temperature must be between 0 and 1")
        }
        if let maxTokens, maxTokens <= 0 {
            throw ValidationError("--max-tokens must be greater than 0")
        }
        if let topK, topK <= 0 {
            throw ValidationError("--top-k must be greater than 0")
        }
        if let topP, !(0...1).contains(topP) || topP == 0 {
            throw ValidationError("--top-p must be greater than 0 and at most 1")
        }
        if sampling != .topK, topK != nil {
            throw ValidationError("--top-k is only valid with --sampling top-k")
        }
        if sampling != .nucleus, topP != nil {
            throw ValidationError("--top-p is only valid with --sampling nucleus")
        }
        let resolvedSampling: AFMGenerationOptions.SamplingMode?
        switch sampling {
        case .greedy:
            resolvedSampling = .greedy
        case .topK:
            resolvedSampling = .randomTop(topK ?? 50, seed: seed)
        case .nucleus:
            resolvedSampling = .randomProbabilityThreshold(topP ?? 0.9, seed: seed)
        case .none:
            resolvedSampling = nil
        }

        guard resolvedSampling != nil || temperature != nil || maxTokens != nil else {
            return nil
        }

        return AFMGenerationOptions(
            sampling: resolvedSampling,
            temperature: temperature,
            maximumResponseTokens: maxTokens
        )
    }
}

struct TranscriptIncludeFlags: ParsableArguments {
    @Flag(name: .long, help: "Include transcript entries in command output.")
    var transcript = false
}

struct TranscriptFileFlags: ParsableArguments {
    @Option(name: .long, help: "File path to write the exported artifact.")
    var file: String
}

func validatedNonEmpty(_ value: String, optionName: String) throws -> String {
    let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedValue.isEmpty else {
        throw ValidationError("Please provide a non-empty \(optionName).")
    }
    return trimmedValue
}

func validatedNonEmptyValues(_ values: [String], optionName: String) throws -> [String] {
    let trimmedValues = values.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    guard !trimmedValues.isEmpty else {
        throw ValidationError("Please provide at least one non-empty \(optionName).")
    }
    return trimmedValues
}

func validatedExportPath(_ path: String, optionName: String = "--file") throws -> String {
    let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedPath.isEmpty else {
        throw ValidationError("Please provide a non-empty \(optionName).")
    }
    return trimmedPath
}

func afmContext() -> AFMInvocationContext {
    AFMInvocationContext(source: .cli, localeIdentifier: Locale.current.identifier)
}

func defaultConversationConfiguration(systemPrompt: String?) -> AFMConversationConfiguration {
    let trimmedSystemPrompt = systemPrompt?.trimmingCharacters(in: .whitespacesAndNewlines)
    let baseInstructions: String

    if let trimmedSystemPrompt, !trimmedSystemPrompt.isEmpty {
        baseInstructions = trimmedSystemPrompt
    } else {
        baseInstructions = "You are a helpful, concise AI assistant."
    }

    return AFMConversationConfiguration(
        baseInstructions: baseInstructions,
        summaryInstructions: "You summarize conversations so the assistant can continue naturally.",
        summaryPromptPreamble: "Summarize this conversation so it can continue naturally:",
        conversationUserLabel: "User:",
        conversationAssistantLabel: "Assistant:",
        continuationNote: "Continue the conversation naturally while preserving prior context.",
        modelUseCase: .general,
        guardrails: .default,
        enableSlidingWindow: true,
        defaultMaxContextSize: 4_096
    )
}

func requireFoundationModelsAvailability() throws -> AFMAvailabilityResult {
    let availability = CheckModelAvailabilityUseCase().execute()
    guard availability.isAvailable else {
        throw AFMRuntimeError.unavailableCapability(availabilityReasonDescription(availability))
    }
    return availability
}

func availabilityReasonDescription(_ availability: AFMAvailabilityResult) -> String {
    if availability.isAvailable {
        return "Apple Intelligence is available and ready to use."
    }

    switch availability.reason {
    case .deviceNotEligible:
        return "This device is not eligible for Apple Intelligence."
    case .appleIntelligenceNotEnabled:
        return "Apple Intelligence is turned off in Settings."
    case .modelNotReady:
        return "Model assets are still being prepared on this device."
    case .unknown, .none:
        return "Apple Intelligence is unavailable for an unknown reason."
    }
}

func currentSupportedLanguageDisplayName(from languages: [AFMSupportedLanguageDescriptor]) -> String {
    let currentLocale = Locale.autoupdatingCurrent
    let currentLanguageCode = currentLocale.language.languageCode?.identifier
    let currentRegionCode = currentLocale.region?.identifier

    if let exactMatch = languages.first(where: {
        $0.languageCode == currentLanguageCode && $0.regionCode == currentRegionCode
    }) {
        return exactMatch.displayName(in: currentLocale)
    }
    if let languageMatch = languages.first(where: { $0.languageCode == currentLanguageCode }) {
        return languageMatch.displayName(in: currentLocale)
    }

    return languages.first?.displayName(in: currentLocale) ?? "English"
}

enum HelpText {
    static let root = """
    MODEL COMMANDS
      model        Inspect model readiness and supported languages.

    SESSION COMMANDS
      session      Run one-shot, streaming, or multi-turn session flows.

    SCHEMA COMMANDS
      schema       Run typed and dynamic schema workflows.

    EXPORT COMMANDS
      transcript   Export transcript data from a session flow.
      feedback     Export Foundation Models feedback attachments.

    QUICK START
      afm model status
      afm session respond --prompt "Summarize Foundation Models in one paragraph."
      afm session stream --prompt "Write a short poem about rain"
      afm session chat --message "Hello" --message "Now answer in French."
      afm schema list
      afm schema run typed-person --input "Jane is a designer in Berlin."
      afm transcript export --message "Hello" --message "Summarize this conversation." --file transcript.json
      afm feedback export --prompt "What is the capital of France?" --sentiment positive --file feedback.json
    """

    static let session = """
    SESSION COMMANDS
      respond     Send one prompt through a fresh session and print the final response.
      stream      Stream one response from a fresh session as it is generated.
      chat        Send multiple prompts through one shared session.
    """

    static let schema = """
    SCHEMA COMMANDS
      list        Show available typed and dynamic schema workflows.
      run         Execute one schema workflow.
    """
}

func suggestRootCommand(for input: String) -> String? {
    let commands = ["model", "session", "schema", "transcript", "feedback", "help", "version"]
    return suggestCommand(input, in: commands)
}

func suggestCommand(_ input: String, in commands: [String]) -> String? {
    let normalizedInput = input.lowercased()
    let ranked = commands
        .map { command in (command, levenshtein(normalizedInput, command)) }
        .sorted { $0.1 < $1.1 }

    guard let best = ranked.first, best.1 <= 3 else {
        return nil
    }
    return best.0
}

func transcriptPayload(_ transcript: Transcript) -> [CLITranscriptEntry] {
    transcript.compactMap { entry in
        switch entry {
        case .prompt(let prompt):
            guard let content = prompt.segments.afmJoinedText() else { return nil }
            return .init(role: "user", content: content)
        case .response(let response):
            guard let content = response.segments.afmJoinedText() else { return nil }
            return .init(role: "assistant", content: content)
        case .toolOutput(let toolOutput):
            guard let content = toolOutput.segments.afmJoinedText() else { return nil }
            return .init(role: "tool", content: content)
        default:
            return nil
        }
    }
}

private func levenshtein(_ lhs: String, _ rhs: String) -> Int {
    let lhsChars = Array(lhs)
    let rhsChars = Array(rhs)
    var distances = Array(0...rhsChars.count)

    for (lhsIndex, lhsChar) in lhsChars.enumerated() {
        var previous = distances[0]
        distances[0] = lhsIndex + 1

        for (rhsIndex, rhsChar) in rhsChars.enumerated() {
            let current = distances[rhsIndex + 1]
            if lhsChar == rhsChar {
                distances[rhsIndex + 1] = previous
            } else {
                distances[rhsIndex + 1] = min(previous, distances[rhsIndex], current) + 1
            }
            previous = current
        }
    }

    return distances[rhsChars.count]
}
