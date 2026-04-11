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
        let availability = CheckModelAvailabilityUseCase().execute()
        let payload = ModelStatusPayload(
            status: availability.isAvailable ? "available" : "unavailable",
            isAvailable: availability.isAvailable,
            reason: availabilityReasonDescription(availability),
            provider: availability.metadata.provider
        )
        let human = """
        Foundation Models
        Status: \(availability.isAvailable ? "Available" : "Unavailable")
        Reason: \(availabilityReasonDescription(availability))
        """

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
        let result = ListSupportedLanguagesUseCase().execute(locale: .current)
        let currentLanguage = currentSupportedLanguageDisplayName(from: result.languages)
        let payload = ModelLanguagesPayload(
            currentLanguage: currentLanguage,
            languages: result.languages.map { language in
                .init(identifier: language.identifier, displayName: language.displayName(in: .current))
            }
        )
        let human = """
        Current language: \(currentLanguage)

        \(result.languages.map { $0.displayName(in: .current) }.joined(separator: "\n"))
        """

        try CLIOutput.emit(payload: payload, human: human, options: resolvedOutput)
    }
}
