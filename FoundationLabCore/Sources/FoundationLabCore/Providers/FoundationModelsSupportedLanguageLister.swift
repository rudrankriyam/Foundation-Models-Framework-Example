import Foundation
import FoundationModels

public struct FoundationModelsSupportedLanguageLister: SupportedLanguageListing {
    public init() {}

    public func supportedLanguages(locale: Locale = .current) -> SupportedLanguagesResult {
        supportedLanguages(useCase: .general, locale: locale)
    }

    public func supportedLanguages(
        useCase: FoundationLabModelUseCase = .general,
        locale: Locale = .current
    ) -> SupportedLanguagesResult {
        let model = SystemLanguageModel(
            useCase: useCase.foundationModelsValue,
            guardrails: FoundationLabGuardrails.default.foundationModelsValue
        )
        let languages = model.supportedLanguages.map { language in
            SupportedLanguageDescriptor(
                identifier: language.maximalIdentifier,
                languageCode: language.languageCode?.identifier ?? "",
                regionCode: language.region?.identifier
            )
        }

        return SupportedLanguagesResult(
            languages: languages,
            metadata: CapabilityExecutionMetadata(
                provider: "Foundation Models",
                modelIdentifier: useCase.rawValue
            )
        )
    }
}
