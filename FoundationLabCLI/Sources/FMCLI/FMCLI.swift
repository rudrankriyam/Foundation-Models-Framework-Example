import ArgumentParser
import Foundation
import FoundationLabCore
import FoundationModels

@main
struct FMCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "fm",
        abstract: "Run Foundation Lab shared capabilities from the command line.",
        subcommands: [
            BookCommand.self
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
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            throw ValidationError("Please provide a non-empty --prompt.")
        }

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
                    context: CapabilityInvocationContext(
                        source: .cli,
                        localeIdentifier: Locale.current.identifier
                    )
                )
            )

            CLIOutput.emit(
                payload: [
                    "title": response.recommendation.title,
                    "author": response.recommendation.author,
                    "genre": response.recommendation.genre.displayName,
                    "description": response.recommendation.description,
                    "metadata": [
                        "provider": response.metadata.provider ?? "",
                        "modelIdentifier": response.metadata.modelIdentifier ?? "",
                        "tokenCount": response.metadata.tokenCount as Any
                    ]
                ],
                human: humanReadableOutput(for: response),
                json: options.json
            )
        } catch {
            CLIOutput.emitError(error, json: options.json)
            throw ExitCode.failure
        }
    }

    private func humanReadableOutput(
        for response: GenerateBookRecommendationResult
    ) -> String {
        var lines = [response.recommendation.plainTextSummary]

        if options.verbose {
            let provider = response.metadata.provider ?? "Unknown"
            let tokenCount = response.metadata.tokenCount.map(String.init) ?? "n/a"
            lines.append("Provider: \(provider)")
            lines.append("Token count: \(tokenCount)")
        }

        return lines.joined(separator: "\n\n")
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

enum CLIAvailabilityError: LocalizedError {
    case foundationModelsUnavailable(String)

    var errorDescription: String? {
        switch self {
        case .foundationModelsUnavailable(let message):
            return message
        }
    }
}

func requireFoundationModelsAvailability() throws {
    switch SystemLanguageModel.default.availability {
    case .available:
        return
    case .unavailable(let reason):
        throw CLIAvailabilityError.foundationModelsUnavailable(
            "Apple Intelligence is unavailable for CLI execution: \(reason)"
        )
    }
}
