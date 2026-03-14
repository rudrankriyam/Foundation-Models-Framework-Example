//
//  LanguageService.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import Foundation
import FoundationLabCore

@MainActor
@Observable
final class LanguageService {
    private let listSupportedLanguagesUseCase = ListSupportedLanguagesUseCase()

    private(set) var supportedLanguages: [SupportedLanguageDescriptor] = []
    private(set) var isLoading = false

    init(autoLoad: Bool = true) {
        if autoLoad {
            Task {
                await loadSupportedLanguages()
            }
        }
    }

    func loadSupportedLanguages() async {
        isLoading = true

        supportedLanguages = listSupportedLanguagesUseCase.execute(locale: .current).languages

        isLoading = false
    }

    func getDisplayName(for language: SupportedLanguageDescriptor) -> String {
        let code = language.languageCode
        let region = language.regionCode ?? ""

        let languageName = Locale.current.localizedString(forLanguageCode: code) ?? code

        if !region.isEmpty {
            return "\(languageName) (\(code)-\(region))"
        } else {
            return languageName
        }
    }

    func getCurrentUserLanguage() -> String {
        return getCurrentUserLanguageDisplayName()
    }

    func getSupportedLanguageNames() -> [String] {
        // Return display names for all supported languages directly
        return supportedLanguages.map { getDisplayName(for: $0) }.sorted()
    }

    func getCurrentUserLanguageDisplayName() -> String {
        let userLocale = Locale.autoupdatingCurrent
        let languageCode = userLocale.language.languageCode?.identifier ?? "en"
        let regionCode = userLocale.region?.identifier

        for language in supportedLanguages where language.languageCode == languageCode && language.regionCode == regionCode {
            return getDisplayName(for: language)
        }

        for language in supportedLanguages where language.languageCode == languageCode {
            return getDisplayName(for: language)
        }

        if let firstLanguage = supportedLanguages.first {
            return getDisplayName(for: firstLanguage)
        }

        return "English"
    }
}
