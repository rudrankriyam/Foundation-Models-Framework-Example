import ArgumentParser
import Foundation
import FoundationLabCore

struct ModelCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "model",
        abstract: "Inspect model availability and supported languages.",
        discussion: CLIHelpText.model,
        subcommands: [
            ModelStatusCommand.self,
            ModelLanguagesCommand.self
        ]
    )
}

struct ModelStatusCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "status",
        abstract: "Check whether Apple Intelligence is available and ready."
    )

    @OptionGroup var options: CLIOptions

    mutating func run() async throws {
        emitStatusCommand(
            options: options,
            commandPath: "model status",
            dryRunHuman: "[dry-run] fm model status"
        )
    }
}

struct ModelLanguagesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "languages",
        abstract: "List the supported model languages from the shared language catalog."
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

func currentSupportedLanguageDisplayName(
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
