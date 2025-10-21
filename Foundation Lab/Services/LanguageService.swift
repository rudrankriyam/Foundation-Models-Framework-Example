//
//  LanguageService.swift
//  FoundationLab
//
//  Created by Assistant on 12/30/25.
//

import Foundation
import FoundationModels

@MainActor
@Observable
final class LanguageService {
    private(set) var supportedLanguages: [Locale.Language] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    init(autoLoad: Bool = true) {
        if autoLoad {
            Task {
                await loadSupportedLanguages()
            }
        }
    }

    func loadSupportedLanguages() async {
        isLoading = true
        errorMessage = nil

        let model = SystemLanguageModel.default
        supportedLanguages = Array(model.supportedLanguages)

        isLoading = false
    }

    func getDisplayName(for language: Locale.Language) -> String {
        let code = language.languageCode?.identifier ?? ""
        let region = language.region?.identifier ?? ""

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

        // Find the matching supported language by code
        for language in supportedLanguages {
            if language.languageCode?.identifier == languageCode {
                return getDisplayName(for: language)
            }
        }

        // Fallback to first supported language
        if let firstLanguage = supportedLanguages.first {
            return getDisplayName(for: firstLanguage)
        }

        // Fallback to "English"
        return "English"
    }
}
