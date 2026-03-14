import ArgumentParser
import Foundation
import FoundationLabCore

struct LanguagesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "languages",
        abstract: "Run the shared Foundation Lab language demos.",
        discussion: CLIHelpText.languages,
        subcommands: [
            ListLanguagesCommand.self,
            RunLanguagesCommand.self
        ]
    )
}

struct RunLanguagesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Run a shared Foundation Lab language demo.",
        subcommands: [
            MultilingualLanguagesCommand.self,
            SessionLanguagesCommand.self,
            NutritionLanguagesCommand.self
        ]
    )
}

struct ListLanguagesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List supported languages using the shared language detection flow."
    )

    @OptionGroup var options: CLIOptions

    mutating func run() async throws {
        let result = ListSupportedLanguagesUseCase().execute(locale: .current)
        let currentLanguage = currentSupportedLanguageDisplayName(from: result.languages)
        let payload: [String: Any] = [
            "currentLanguage": currentLanguage,
            "languages": result.languages.map { language in
                [
                    "identifier": language.identifier,
                    "displayName": language.displayName(in: .current)
                ]
            }
        ]

        let human = """
        Current language: \(currentLanguage)

        \(result.languages.map { $0.displayName(in: .current) }.joined(separator: "\n"))
        """

        CLIOutput.emit(payload: payload, human: human, json: options.json)
    }
}

struct MultilingualLanguagesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "multilingual",
        abstract: "Run the shared multilingual responses demo."
    )

    @OptionGroup var options: CLIOptions

    @Option(name: .customLong("limit"), help: "Maximum number of language prompts to run.")
    var limit: Int?

    mutating func run() async throws {
        if options.dryRun {
            CLIOutput.emit(
                payload: [
                    "status": "dry_run",
                    "command": "languages run multilingual",
                    "limit": limit as Any
                ],
                human: "[dry-run] fm languages run multilingual",
                json: options.json
            )
            return
        }

        do {
            try requireFoundationModelsAvailability()

            let result = try await GenerateMultilingualResponsesUseCase().execute(
                GenerateMultilingualResponsesRequest(
                    maximumResults: limit,
                    context: cliContext()
                )
            )

            CLIOutput.emit(
                payload: [
                    "responses": result.responses.map { response in
                        [
                            "language": response.language,
                            "prompt": response.prompt,
                            "response": response.response,
                            "isError": response.isError
                        ]
                    },
                    "metadata": metadataPayload(result.metadata)
                ],
                human: humanReadableMultilingualResponses(result.responses, verbose: options.verbose),
                json: options.json
            )
        } catch {
            CLIOutput.emitError(error, json: options.json)
            throw ExitCode.failure
        }
    }
}

struct SessionLanguagesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "session",
        abstract: "Run the shared multilingual session demo."
    )

    @OptionGroup var options: CLIOptions

    @Option(name: .long, help: "Override the default system prompt.")
    var systemPrompt: String?

    mutating func run() async throws {
        if options.dryRun {
            CLIOutput.emit(
                payload: [
                    "status": "dry_run",
                    "command": "languages run session",
                    "systemPrompt": systemPrompt ?? ""
                ],
                human: "[dry-run] fm languages run session",
                json: options.json
            )
            return
        }

        do {
            try requireFoundationModelsAvailability()

            let result = try await RunLanguageSessionDemoUseCase().execute(
                RunLanguageSessionDemoRequest(
                    systemPrompt: systemPrompt ?? FoundationLabLanguageCatalog.multilingualSystemPrompt,
                    context: cliContext()
                )
            )

            CLIOutput.emit(
                payload: [
                    "exchanges": result.exchanges.map { exchange in
                        [
                            "label": exchange.label,
                            "prompt": exchange.prompt,
                            "response": exchange.response,
                            "isError": exchange.isError
                        ]
                    },
                    "metadata": metadataPayload(result.metadata)
                ],
                human: humanReadableLanguageSession(result.exchanges, verbose: options.verbose),
                json: options.json
            )
        } catch {
            CLIOutput.emitError(error, json: options.json)
            throw ExitCode.failure
        }
    }
}

struct NutritionLanguagesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "nutrition",
        abstract: "Run the shared multilingual nutrition example."
    )

    @OptionGroup var options: CLIOptions

    @Option(name: [.short, .long], help: "Food description to analyze.")
    var description: String?

    @Option(name: .long, help: "Preferred response language.")
    var language: String?

    mutating func run() async throws {
        let resolvedDescription = try validatedNonEmpty(
            description ?? "I had 2 scrambled eggs with toast for breakfast",
            optionName: "--description"
        )
        let resolvedLanguage = try validatedNonEmpty(
            language ?? currentSupportedLanguageDisplayName(from: ListSupportedLanguagesUseCase().execute(locale: .current).languages),
            optionName: "--language"
        )

        if options.dryRun {
            CLIOutput.emit(
                payload: [
                    "status": "dry_run",
                    "command": "languages run nutrition",
                    "description": resolvedDescription,
                    "language": resolvedLanguage
                ],
                human: """
                [dry-run] fm languages run nutrition
                Description: \(resolvedDescription)
                Language: \(resolvedLanguage)
                """,
                json: options.json
            )
            return
        }

        do {
            try requireFoundationModelsAvailability()

            let result = try await AnalyzeNutritionUseCase().execute(
                AnalyzeNutritionRequest(
                    foodDescription: resolvedDescription,
                    responseLanguage: resolvedLanguage,
                    context: cliContext()
                )
            )

            CLIOutput.emit(
                payload: [
                    "language": resolvedLanguage,
                    "foodName": result.analysis.foodName,
                    "calories": result.analysis.calories,
                    "proteinGrams": result.analysis.proteinGrams,
                    "carbsGrams": result.analysis.carbsGrams,
                    "fatGrams": result.analysis.fatGrams,
                    "insights": result.analysis.insights,
                    "metadata": metadataPayload(result.metadata)
                ],
                human: humanReadableNutritionOutput(for: result, verbose: options.verbose),
                json: options.json
            )
        } catch {
            CLIOutput.emitError(error, json: options.json)
            throw ExitCode.failure
        }
    }
}

private func currentSupportedLanguageDisplayName(
    from languages: [SupportedLanguageDescriptor]
) -> String {
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

private func humanReadableMultilingualResponses(
    _ responses: [MultilingualResponseEntry],
    verbose: Bool
) -> String {
    var lines: [String] = []

    for response in responses {
        lines.append("\(response.flag) \(response.language)")
        lines.append("Prompt: \(response.prompt)")
        lines.append("Response: \(response.response)")

        if verbose {
            let tokenCount = response.metadata?.tokenCount.map(String.init) ?? "n/a"
            lines.append("Token count: \(tokenCount)")
        }

        lines.append("")
    }

    if !lines.isEmpty {
        lines.removeLast()
    }

    return lines.joined(separator: "\n")
}

private func humanReadableLanguageSession(
    _ exchanges: [LanguageSessionExchange],
    verbose: Bool
) -> String {
    var lines: [String] = []

    for exchange in exchanges {
        lines.append(exchange.label)
        lines.append("Prompt: \(exchange.prompt)")
        lines.append("Response: \(exchange.response)")
        lines.append("")
    }

    if !lines.isEmpty {
        lines.removeLast()
    }

    if verbose {
        lines.append("")
        lines.append("Steps: \(exchanges.count)")
    }

    return lines.joined(separator: "\n")
}
