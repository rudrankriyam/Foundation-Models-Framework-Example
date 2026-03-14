import Foundation

public protocol SupportedLanguageListing: Sendable {
    func supportedLanguages(locale: Locale) -> SupportedLanguagesResult
}
