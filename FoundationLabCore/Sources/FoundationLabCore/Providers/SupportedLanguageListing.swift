import Foundation

public protocol SupportedLanguageListing: Sendable {
    func supportedLanguages(locale: Locale) -> SupportedLanguagesResult
    func supportedLanguages(
        useCase: FoundationLabModelUseCase,
        locale: Locale
    ) -> SupportedLanguagesResult
}

public extension SupportedLanguageListing {
    func supportedLanguages(
        useCase _: FoundationLabModelUseCase,
        locale: Locale
    ) -> SupportedLanguagesResult {
        supportedLanguages(locale: locale)
    }
}
