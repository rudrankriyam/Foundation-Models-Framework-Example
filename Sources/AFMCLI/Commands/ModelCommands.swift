import ArgumentParser
import Foundation

struct ModelCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "model",
        abstract: "Inspect model readiness and supported languages.",
        subcommands: [
            ModelStatusCommand.self,
            ModelLanguagesCommand.self
        ]
    )
}

struct ModelStatusPayload: Encodable {
    let status: String
    let isAvailable: Bool
    let reason: String
    let provider: String?
}

struct ModelStatusCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "status",
        abstract: "Check whether Apple Intelligence is available and ready."
    )

    @OptionGroup var options: GlobalCommandOptions

    mutating func run() async throws {
        let resolvedOutput = try options.resolvedOutput()
        if options.dryRun {
            try CLIOutput.emit(
                payload: DryRunPayload(command: "model status"),
                human: "[dry-run] afm model status",
                options: resolvedOutput
            )
            return
        }

        let availability = CheckModelAvailabilityUseCase().execute()
        let payload = ModelStatusPayload(
            status: availability.isAvailable ? "available" : "unavailable",
            isAvailable: availability.isAvailable,
            reason: availabilityReasonDescription(availability),
            provider: availability.metadata.provider
        )
        var lines = [
            "Foundation Models",
            "Status: \(availability.isAvailable ? "Available" : "Unavailable")",
            "Reason: \(availabilityReasonDescription(availability))"
        ]
        if options.verbose, let provider = availability.metadata.provider {
            lines.append("Provider: \(provider)")
        }
        let human = lines.joined(separator: "\n")

        try CLIOutput.emit(payload: payload, human: human, options: resolvedOutput)
    }
}

struct ModelLanguagesPayload: Encodable {
    struct Language: Encodable {
        let identifier: String
        let displayName: String
    }

    let currentLanguage: String
    let languages: [Language]
}

struct ModelLanguagesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "languages",
        abstract: "List the languages supported by the current model runtime."
    )

    @OptionGroup var options: GlobalCommandOptions

    mutating func run() async throws {
        let resolvedOutput = try options.resolvedOutput()
        if options.dryRun {
            try CLIOutput.emit(
                payload: DryRunPayload(command: "model languages"),
                human: "[dry-run] afm model languages",
                options: resolvedOutput
            )
            return
        }

        let result = ListSupportedLanguagesUseCase().execute(locale: .current)
        let currentLanguage = currentSupportedLanguageDisplayName(from: result.languages)
        let payload = ModelLanguagesPayload(
            currentLanguage: currentLanguage,
            languages: result.languages.map { language in
                .init(identifier: language.identifier, displayName: language.displayName(in: .current))
            }
        )
        var lines = [
            "Current language: \(currentLanguage)",
            "",
            result.languages.map { $0.displayName(in: .current) }.joined(separator: "\n")
        ]
        if options.verbose {
            lines.append("")
            lines.append("Supported language count: \(result.languages.count)")
        }
        let human = lines.joined(separator: "\n")

        try CLIOutput.emit(payload: payload, human: human, options: resolvedOutput)
    }
}
