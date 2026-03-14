import ArgumentParser
import Foundation
import FoundationLabCore

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
                    "command": "tools weather get",
                    "location": trimmedLocation
                ],
                human: """
                [dry-run] fm tools weather get
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
                    "command": "tools web search",
                    "query": trimmedQuery
                ],
                human: """
                [dry-run] fm tools web search
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
                    "command": "tools web summary",
                    "url": trimmedURL
                ],
                human: """
                [dry-run] fm tools web summary
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
