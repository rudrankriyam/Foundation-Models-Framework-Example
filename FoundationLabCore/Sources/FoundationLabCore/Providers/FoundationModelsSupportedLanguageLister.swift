import Foundation
import FoundationModels

public struct FoundationModelsSupportedLanguageLister: SupportedLanguageListing {
    public init() {}

    public func supportedLanguages(locale: Locale = .current) -> SupportedLanguagesResult {
        let languages = SystemLanguageModel.default.supportedLanguages.map { language in
            SupportedLanguageDescriptor(
                identifier: language.maximalIdentifier,
                languageCode: language.languageCode?.identifier ?? "",
                regionCode: language.region?.identifier
            )
        }

        return SupportedLanguagesResult(
            languages: languages,
            metadata: CapabilityExecutionMetadata(provider: "Foundation Models")
        )
    }
}
