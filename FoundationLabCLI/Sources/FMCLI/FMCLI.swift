import ArgumentParser
import Foundation
import FoundationLabCore

@main
struct FMCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "fm",
        abstract: "Run Foundation Lab shared capabilities from the command line.",
        subcommands: [
            StatusCommand.self,
            BookCommand.self,
            NutritionCommand.self,
            WeatherCommand.self,
            WebCommand.self,
            ExamplesCommand.self,
            SchemasCommand.self,
            LanguagesCommand.self,
            ChatCommand.self,
            ContactsCommand.self,
            CalendarCommand.self,
            RemindersCommand.self,
            LocationCommand.self,
            MusicCommand.self,
            HealthCommand.self
        ],
        defaultSubcommand: BookCommand.self
    )
}

struct CLIOptions: ParsableArguments {
    @Flag(name: .long, help: "Emit machine-readable JSON.")
    var json = false

    @Flag(name: .customLong("dry-run"), help: "Print the request without executing it.")
    var dryRun = false

    @Flag(name: .long, help: "Include execution metadata in human-readable output.")
    var verbose = false
}

struct BookCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "book",
        abstract: "Book recommendation capabilities.",
        subcommands: [
            RecommendBookCommand.self
        ],
        defaultSubcommand: RecommendBookCommand.self
    )
}

struct NutritionCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "nutrition",
        abstract: "Nutrition analysis capabilities.",
        subcommands: [
            AnalyzeNutritionCommand.self
        ],
        defaultSubcommand: AnalyzeNutritionCommand.self
    )
}

struct WeatherCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "weather",
        abstract: "Weather capabilities.",
        subcommands: [
            GetWeatherCommand.self
        ],
        defaultSubcommand: GetWeatherCommand.self
    )
}

struct WebCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "web",
        abstract: "Web capabilities.",
        subcommands: [
            SearchWebCommand.self,
            SummarizeWebPageCommand.self
        ],
        defaultSubcommand: SearchWebCommand.self
    )
}

struct ChatCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "chat",
        abstract: "Multi-turn conversation capabilities.",
        subcommands: [
            RunChatCommand.self
        ],
        defaultSubcommand: RunChatCommand.self
    )
}

struct ContactsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "contacts",
        abstract: "Contacts capabilities.",
        subcommands: [
            SearchContactsCommand.self
        ],
        defaultSubcommand: SearchContactsCommand.self
    )
}

struct CalendarCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "calendar",
        abstract: "Calendar capabilities.",
        subcommands: [
            QueryCalendarCommand.self
        ],
        defaultSubcommand: QueryCalendarCommand.self
    )
}

struct RemindersCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "reminders",
        abstract: "Reminders capabilities.",
        subcommands: [
            ManageRemindersCLICommand.self
        ],
        defaultSubcommand: ManageRemindersCLICommand.self
    )
}

struct LocationCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "location",
        abstract: "Location capabilities.",
        subcommands: [
            GetCurrentLocationCommand.self
        ],
        defaultSubcommand: GetCurrentLocationCommand.self
    )
}

struct MusicCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "music",
        abstract: "Music capabilities.",
        subcommands: [
            SearchMusicCommand.self
        ],
        defaultSubcommand: SearchMusicCommand.self
    )
}

struct HealthCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "health",
        abstract: "Health capabilities.",
        subcommands: [
            QueryHealthCommand.self
        ],
        defaultSubcommand: QueryHealthCommand.self
    )
}

struct RunChatCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Run one or more messages through the shared conversation engine."
    )

    @OptionGroup var options: CLIOptions

    @Option(
        name: [.short, .long],
        parsing: .upToNextOption,
        help: "Message(s) to send through one shared session. Repeat the option for multi-turn chat."
    )
    var message: [String] = []

    @Option(name: .long, help: "Optional system instructions for the shared conversation engine.")
    var systemPrompt: String?

    @Flag(name: .long, help: "Stream each assistant response while it is generated.")
    var stream = false

    mutating func run() async throws {
        let validatedMessages = try validatedNonEmptyValues(message, optionName: "--message")

        if options.dryRun {
            CLIOutput.emit(
                payload: [
                    "status": "dry_run",
                    "command": "chat run",
                    "messages": validatedMessages,
                    "systemPrompt": systemPrompt ?? "",
                    "stream": stream
                ],
                human: """
                [dry-run] fm chat run
                Messages: \(validatedMessages.count)
                Stream: \(stream ? "yes" : "no")
                """,
                json: options.json
            )
            return
        }

        do {
            try requireFoundationModelsAvailability()

            let engine = await MainActor.run {
                FoundationLabConversationEngine(
                    configuration: cliConversationConfiguration(systemPrompt: systemPrompt)
                )
            }

            var exchanges: [[String: String]] = []

            for entry in validatedMessages {
                let response: String

                if stream && !options.json {
                    print("User: \(entry)")
                    print("Assistant: ", terminator: "")
                    fflush(stdout)

                    var latestPrinted = ""
                    response = try await engine.sendStreamingMessage(
                        entry,
                        onPartialResponse: { partialResponse in
                            guard partialResponse.hasPrefix(latestPrinted) else {
                                let suffix = partialResponse
                                print(suffix, terminator: "")
                                fflush(stdout)
                                latestPrinted = partialResponse
                                return
                            }

                            let suffix = String(partialResponse.dropFirst(latestPrinted.count))
                            guard !suffix.isEmpty else { return }
                            print(suffix, terminator: "")
                            fflush(stdout)
                            latestPrinted = partialResponse
                        }
                    )
                    print("\n")
                } else {
                    response = try await engine.sendMessage(entry)
                }

                exchanges.append([
                    "message": entry,
                    "response": response
                ])
            }

            let payload: [String: Any] = [
                "exchanges": exchanges,
                "sessionCount": await MainActor.run { engine.sessionCount },
                "tokenCount": await MainActor.run { engine.currentTokenCount }
            ]

            CLIOutput.emit(
                payload: payload,
                human: humanReadableConversationOutput(
                    exchanges: exchanges,
                    sessionCount: await MainActor.run { engine.sessionCount },
                    tokenCount: await MainActor.run { engine.currentTokenCount },
                    verbose: options.verbose,
                    streamed: stream && !options.json
                ),
                json: options.json
            )
        } catch {
            CLIOutput.emitError(error, json: options.json)
            throw ExitCode.failure
        }
    }
}

struct RecommendBookCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "recommend",
        abstract: "Generate a book recommendation."
    )

    @OptionGroup var options: CLIOptions

    @Option(name: [.short, .long], help: "Describe the kind of book recommendation you want.")
    var prompt: String

    @Option(name: .long, help: "Optional system instructions for the shared capability.")
    var systemPrompt: String?

    mutating func run() async throws {
        let trimmedPrompt = try validatedNonEmpty(prompt, optionName: "--prompt")

        if options.dryRun {
            CLIOutput.emit(
                payload: [
                    "status": "dry_run",
                    "command": "book recommend",
                    "prompt": trimmedPrompt,
                    "systemPrompt": systemPrompt ?? ""
                ],
                human: """
                [dry-run] fm book recommend
                Prompt: \(trimmedPrompt)
                """,
                json: options.json
            )
            return
        }

        do {
            try requireFoundationModelsAvailability()

            let response = try await GenerateBookRecommendationUseCase().execute(
                GenerateBookRecommendationRequest(
                    prompt: trimmedPrompt,
                    systemPrompt: systemPrompt,
                    context: cliContext()
                )
            )

            CLIOutput.emit(
                payload: [
                    "title": response.recommendation.title,
                    "author": response.recommendation.author,
                    "genre": response.recommendation.genre.displayName,
                    "description": response.recommendation.description,
                    "metadata": metadataPayload(response.metadata)
                ],
                human: humanReadableBookOutput(for: response, verbose: options.verbose),
                json: options.json
            )
        } catch {
            CLIOutput.emitError(error, json: options.json)
            throw ExitCode.failure
        }
    }
}

struct AnalyzeNutritionCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "analyze",
        abstract: "Analyze a meal description."
    )

    @OptionGroup var options: CLIOptions

    @Option(name: [.short, .long], help: "Describe the food or meal to analyze.")
    var description: String

    @Option(name: .long, help: "Preferred response language.", completion: .default)
    var language = "English"

    mutating func run() async throws {
        let trimmedDescription = try validatedNonEmpty(description, optionName: "--description")
        let trimmedLanguage = try validatedNonEmpty(language, optionName: "--language")

        if options.dryRun {
            CLIOutput.emit(
                payload: [
                    "status": "dry_run",
                    "command": "nutrition analyze",
                    "description": trimmedDescription,
                    "language": trimmedLanguage
                ],
                human: """
                [dry-run] fm nutrition analyze
                Description: \(trimmedDescription)
                Language: \(trimmedLanguage)
                """,
                json: options.json
            )
            return
        }

        do {
            try requireFoundationModelsAvailability()

            let response = try await AnalyzeNutritionUseCase().execute(
                AnalyzeNutritionRequest(
                    foodDescription: trimmedDescription,
                    responseLanguage: trimmedLanguage,
                    context: cliContext()
                )
            )

            CLIOutput.emit(
                payload: [
                    "foodName": response.analysis.foodName,
                    "calories": response.analysis.calories,
                    "proteinGrams": response.analysis.proteinGrams,
                    "carbsGrams": response.analysis.carbsGrams,
                    "fatGrams": response.analysis.fatGrams,
                    "insights": response.analysis.insights,
                    "metadata": metadataPayload(response.metadata)
                ],
                human: humanReadableNutritionOutput(for: response, verbose: options.verbose),
                json: options.json
            )
        } catch {
            CLIOutput.emitError(error, json: options.json)
            throw ExitCode.failure
        }
    }
}

struct GetWeatherCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get the weather for a location."
    )

    @OptionGroup var options: CLIOptions

    @Option(name: [.short, .long], help: "The location to look up.")
    var location: String

    mutating func run() async throws {
        let trimmedLocation = try validatedNonEmpty(location, optionName: "--location")

        if options.dryRun {
            CLIOutput.emit(
                payload: [
                    "status": "dry_run",
                    "command": "weather get",
                    "location": trimmedLocation
                ],
                human: """
                [dry-run] fm weather get
                Location: \(trimmedLocation)
                """,
                json: options.json
            )
            return
        }

        do {
            try requireFoundationModelsAvailability()

            let response = try await GetWeatherUseCase().execute(
                GetWeatherRequest(
                    location: trimmedLocation,
                    context: cliContext()
                )
            )

            CLIOutput.emit(
                payload: [
                    "location": trimmedLocation,
                    "content": response.content,
                    "metadata": metadataPayload(response.metadata)
                ],
                human: humanReadableText(
                    title: "Weather for \(trimmedLocation)",
                    response: response,
                    verbose: options.verbose
                ),
                json: options.json
            )
        } catch {
            CLIOutput.emitError(error, json: options.json)
            throw ExitCode.failure
        }
    }
}

struct SearchWebCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "search",
        abstract: "Search the web with the shared web search capability."
    )

    @OptionGroup var options: CLIOptions

    @Option(name: [.short, .long], help: "The search query to run.")
    var query: String

    mutating func run() async throws {
        let trimmedQuery = try validatedNonEmpty(query, optionName: "--query")

        if options.dryRun {
            CLIOutput.emit(
                payload: [
                    "status": "dry_run",
                    "command": "web search",
                    "query": trimmedQuery
                ],
                human: """
                [dry-run] fm web search
                Query: \(trimmedQuery)
                """,
                json: options.json
            )
            return
        }

        do {
            try requireFoundationModelsAvailability()

            let response = try await SearchWebUseCase().execute(
                SearchWebRequest(
                    query: trimmedQuery,
                    context: cliContext()
                )
            )

            CLIOutput.emit(
                payload: [
                    "query": trimmedQuery,
                    "content": response.content,
                    "metadata": metadataPayload(response.metadata)
                ],
                human: humanReadableText(
                    title: "Web search for \(trimmedQuery)",
                    response: response,
                    verbose: options.verbose
                ),
                json: options.json
            )
        } catch {
            CLIOutput.emitError(error, json: options.json)
            throw ExitCode.failure
        }
    }
}

struct SummarizeWebPageCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "summary",
        abstract: "Summarize a web page."
    )

    @OptionGroup var options: CLIOptions

    @Option(name: [.short, .long], help: "The page URL to summarize.")
    var url: String

    mutating func run() async throws {
        let trimmedURL = try validatedNonEmpty(url, optionName: "--url")

        if options.dryRun {
            CLIOutput.emit(
                payload: [
                    "status": "dry_run",
                    "command": "web summary",
                    "url": trimmedURL
                ],
                human: """
                [dry-run] fm web summary
                URL: \(trimmedURL)
                """,
                json: options.json
            )
            return
        }

        do {
            try requireFoundationModelsAvailability()

            let response = try await GenerateWebPageSummaryUseCase().execute(
                GenerateWebPageSummaryRequest(
                    url: trimmedURL,
                    context: cliContext()
                )
            )

            CLIOutput.emit(
                payload: [
                    "url": trimmedURL,
                    "content": response.content,
                    "metadata": metadataPayload(response.metadata)
                ],
                human: humanReadableText(
                    title: "Web page summary",
                    response: response,
                    verbose: options.verbose
                ),
                json: options.json
            )
        } catch {
            CLIOutput.emitError(error, json: options.json)
            throw ExitCode.failure
        }
    }
}

struct SearchContactsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "search",
        abstract: "Search contacts."
    )

    @OptionGroup var options: CLIOptions

    @Option(name: [.short, .long], help: "The contact search query.")
    var query: String

    mutating func run() async throws {
        let trimmedQuery = try validatedNonEmpty(query, optionName: "--query")

        if options.dryRun {
            CLIOutput.emit(
                payload: [
                    "status": "dry_run",
                    "command": "contacts search",
                    "query": trimmedQuery
                ],
                human: """
                [dry-run] fm contacts search
                Query: \(trimmedQuery)
                """,
                json: options.json
            )
            return
        }

        do {
            try requireUnsupportedCLICapability("Contacts")
        } catch {
            CLIOutput.emitError(error, json: options.json)
            throw ExitCode.failure
        }
    }
}

struct QueryCalendarCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "query",
        abstract: "Query calendar events."
    )

    @OptionGroup var options: CLIOptions

    @Option(name: [.short, .long], help: "The natural-language calendar request.")
    var request: String

    mutating func run() async throws {
        let trimmedRequest = try validatedNonEmpty(request, optionName: "--request")

        if options.dryRun {
            CLIOutput.emit(
                payload: [
                    "status": "dry_run",
                    "command": "calendar query",
                    "request": trimmedRequest
                ],
                human: """
                [dry-run] fm calendar query
                Request: \(trimmedRequest)
                """,
                json: options.json
            )
            return
        }

        do {
            try requireUnsupportedCLICapability("Calendar")
        } catch {
            CLIOutput.emitError(error, json: options.json)
            throw ExitCode.failure
        }
    }
}

struct ManageRemindersCLICommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "request",
        abstract: "Create or manage reminders."
    )

    @OptionGroup var options: CLIOptions

    @Option(name: [.short, .long], help: "The natural-language reminders request.")
    var prompt: String

    mutating func run() async throws {
        let trimmedPrompt = try validatedNonEmpty(prompt, optionName: "--prompt")

        if options.dryRun {
            CLIOutput.emit(
                payload: [
                    "status": "dry_run",
                    "command": "reminders request",
                    "prompt": trimmedPrompt
                ],
                human: """
                [dry-run] fm reminders request
                Prompt: \(trimmedPrompt)
                """,
                json: options.json
            )
            return
        }

        do {
            try requireUnsupportedCLICapability("Reminders")
        } catch {
            CLIOutput.emitError(error, json: options.json)
            throw ExitCode.failure
        }
    }
}

struct GetCurrentLocationCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "current",
        abstract: "Get the current location."
    )

    @OptionGroup var options: CLIOptions

    mutating func run() async throws {
        if options.dryRun {
            CLIOutput.emit(
                payload: [
                    "status": "dry_run",
                    "command": "location current"
                ],
                human: "[dry-run] fm location current",
                json: options.json
            )
            return
        }

        do {
            try requireUnsupportedCLICapability("Location")
        } catch {
            CLIOutput.emitError(error, json: options.json)
            throw ExitCode.failure
        }
    }
}

struct SearchMusicCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "search",
        abstract: "Search the Apple Music catalog."
    )

    @OptionGroup var options: CLIOptions

    @Option(name: [.short, .long], help: "The music search query.")
    var query: String

    mutating func run() async throws {
        let trimmedQuery = try validatedNonEmpty(query, optionName: "--query")

        if options.dryRun {
            CLIOutput.emit(
                payload: [
                    "status": "dry_run",
                    "command": "music search",
                    "query": trimmedQuery
                ],
                human: """
                [dry-run] fm music search
                Query: \(trimmedQuery)
                """,
                json: options.json
            )
            return
        }

        do {
            try requireUnsupportedCLICapability("Music")
        } catch {
            CLIOutput.emitError(error, json: options.json)
            throw ExitCode.failure
        }
    }
}

struct QueryHealthCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "query",
        abstract: "Query health data."
    )

    @OptionGroup var options: CLIOptions

    @Option(name: [.short, .long], help: "The health data question to ask.")
    var request: String

    mutating func run() async throws {
        let trimmedRequest = try validatedNonEmpty(request, optionName: "--request")

        if options.dryRun {
            CLIOutput.emit(
                payload: [
                    "status": "dry_run",
                    "command": "health query",
                    "request": trimmedRequest
                ],
                human: """
                [dry-run] fm health query
                Request: \(trimmedRequest)
                """,
                json: options.json
            )
            return
        }

        do {
            try requireUnsupportedCLICapability("Health")
        } catch {
            CLIOutput.emitError(error, json: options.json)
            throw ExitCode.failure
        }
    }
}

enum CLIOutput {
    static func emit(payload: [String: Any], human: String, json: Bool) {
        if json {
            emitJSON(payload)
        } else {
            print(human)
        }
    }

    static func emitError(_ error: Error, json: Bool) {
        let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription

        if json {
            emitJSON([
                "status": "error",
                "message": message
            ])
        } else {
            fputs("Error: \(message)\n", stderr)
        }
    }

    private static func emitJSON(_ payload: [String: Any]) {
        guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(
                withJSONObject: payload,
                options: [.prettyPrinted, .sortedKeys]
              ),
              let text = String(data: data, encoding: .utf8) else {
            print("{\"status\":\"error\",\"message\":\"Failed to encode JSON output.\"}")
            return
        }

        print(text)
    }
}

func humanReadableBookOutput(
    for response: GenerateBookRecommendationResult,
    verbose: Bool
) -> String {
    var lines = [response.recommendation.plainTextSummary]

    if verbose {
        let provider = response.metadata.provider ?? "Unknown"
        let tokenCount = response.metadata.tokenCount.map(String.init) ?? "n/a"
        lines.append("Provider: \(provider)")
        lines.append("Token count: \(tokenCount)")
    }

    return lines.joined(separator: "\n\n")
}

func humanReadableNutritionOutput(
    for response: AnalyzeNutritionResult,
    verbose: Bool
) -> String {
    var lines = [
        response.analysis.foodName,
        "",
        "Calories: \(response.analysis.calories)",
        "Protein: \(response.analysis.proteinGrams)g",
        "Carbs: \(response.analysis.carbsGrams)g",
        "Fat: \(response.analysis.fatGrams)g",
        "",
        response.analysis.insights
    ]

    if verbose {
        let provider = response.metadata.provider ?? "Unknown"
        let tokenCount = response.metadata.tokenCount.map(String.init) ?? "n/a"
        lines.append("")
        lines.append("Provider: \(provider)")
        lines.append("Token count: \(tokenCount)")
    }

    return lines.joined(separator: "\n")
}

func humanReadableText(
    title: String,
    response: TextGenerationResult,
    verbose: Bool
) -> String {
    var lines = [title, "", response.content]

    if verbose {
        let provider = response.metadata.provider ?? "Unknown"
        let tokenCount = response.metadata.tokenCount.map(String.init) ?? "n/a"
        lines.append("")
        lines.append("Provider: \(provider)")
        lines.append("Token count: \(tokenCount)")
    }

    return lines.joined(separator: "\n")
}

func humanReadableConversationOutput(
    exchanges: [[String: String]],
    sessionCount: Int,
    tokenCount: Int,
    verbose: Bool,
    streamed: Bool
) -> String {
    var lines: [String] = []

    if !streamed {
        for exchange in exchanges {
            lines.append("User: \(exchange["message"] ?? "")")
            lines.append("Assistant: \(exchange["response"] ?? "")")
            lines.append("")
        }

        if !lines.isEmpty {
            lines.removeLast()
        }
    }

    if verbose {
        if !lines.isEmpty {
            lines.append("")
        }
        lines.append("Sessions: \(sessionCount)")
        lines.append("Token count: \(tokenCount)")
    }

    return lines.joined(separator: "\n")
}

func metadataPayload(_ metadata: CapabilityExecutionMetadata) -> [String: Any] {
    [
        "provider": metadata.provider ?? "",
        "modelIdentifier": metadata.modelIdentifier ?? "",
        "tokenCount": metadata.tokenCount as Any
    ]
}

enum CLIAvailabilityError: LocalizedError {
    case foundationModelsUnavailable(String)

    var errorDescription: String? {
        switch self {
        case .foundationModelsUnavailable(let message):
            return message
        }
    }
}

func validatedNonEmpty(_ value: String, optionName: String) throws -> String {
    let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedValue.isEmpty else {
        throw ValidationError("Please provide a non-empty \(optionName).")
    }
    return trimmedValue
}

func validatedNonEmptyValues(_ values: [String], optionName: String) throws -> [String] {
    let trimmedValues = values.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
    guard !trimmedValues.isEmpty else {
        throw ValidationError("Please provide at least one non-empty \(optionName).")
    }
    return trimmedValues
}

func cliContext() -> CapabilityInvocationContext {
    CapabilityInvocationContext(
        source: .cli,
        localeIdentifier: Locale.current.identifier
    )
}

func cliConversationConfiguration(systemPrompt: String?) -> FoundationLabConversationConfiguration {
    let trimmedSystemPrompt = systemPrompt?.trimmingCharacters(in: .whitespacesAndNewlines)
    let baseInstructions: String

    if let trimmedSystemPrompt, !trimmedSystemPrompt.isEmpty {
        baseInstructions = trimmedSystemPrompt
    } else {
        baseInstructions = """
        You are a helpful, friendly AI assistant. Engage in natural conversation and provide \
        thoughtful, detailed responses.
        """
    }

    return FoundationLabConversationConfiguration(
        baseInstructions: baseInstructions,
        summaryInstructions: """
        You are an expert at summarizing conversations. Create concise summaries that preserve \
        context needed to continue naturally.
        """,
        summaryPromptPreamble: """
        Please summarize the following conversation so the assistant can continue it naturally:
        """,
        conversationUserLabel: "User:",
        conversationAssistantLabel: "Assistant:",
        continuationNote: """
        Continue the conversation naturally, using this context when relevant.
        """,
        modelUseCase: .general,
        guardrails: .default,
        enableSlidingWindow: true,
        defaultMaxContextSize: 4_096
    )
}

func requireUnsupportedCLICapability(_ name: String) throws {
    throw FoundationLabCoreError.unsupportedEnvironment(
        "\(name) is only supported in the Foundation Lab app or its App Intents because command-line execution does not have the required system entitlements and permissions."
    )
}

func requireFoundationModelsAvailability() throws {
    let availability = CheckModelAvailabilityUseCase().execute()

    if availability.isAvailable {
        return
    }

    let reasonDescription: String
    switch availability.reason {
    case .deviceNotEligible:
        reasonDescription = "device not eligible"
    case .appleIntelligenceNotEnabled:
        reasonDescription = "Apple Intelligence not enabled"
    case .modelNotReady:
        reasonDescription = "model not ready"
    case .unknown, .none:
        reasonDescription = "unknown reason"
    }

    throw CLIAvailabilityError.foundationModelsUnavailable(
        "Apple Intelligence is unavailable for CLI execution: \(reasonDescription)"
    )
}
