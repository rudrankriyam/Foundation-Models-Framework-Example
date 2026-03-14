import ArgumentParser
import Foundation
import FoundationLabCore

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
