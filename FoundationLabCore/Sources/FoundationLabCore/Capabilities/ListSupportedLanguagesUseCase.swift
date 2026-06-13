import Foundation

public struct ListSupportedLanguagesUseCase: Sendable {
    public static let descriptor = CapabilityDescriptor(
        id: "foundation-models.list-supported-languages",
        displayName: "List Supported Languages",
        summary: "Lists the languages supported by the current Foundation Models runtime."
    )

    private let lister: any SupportedLanguageListing

    public init(lister: any SupportedLanguageListing = FoundationModelsSupportedLanguageLister()) {
        self.lister = lister
    }

    public func execute(
        useCase: FoundationLabModelUseCase = .general,
        locale: Locale = .current
    ) -> SupportedLanguagesResult {
        lister.supportedLanguages(useCase: useCase, locale: locale)
    }
}
