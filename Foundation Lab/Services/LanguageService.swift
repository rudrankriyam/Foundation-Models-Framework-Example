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
class LanguageService {
    static let shared = LanguageService()
    
    private(set) var supportedLanguages: [Locale.Language] = []
    private(set) var languageMapping: [String: String] = [:]
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    
    private init() {
        Task {
            await loadSupportedLanguages()
        }
    }
    
    func loadSupportedLanguages() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let model = SystemLanguageModel.default
            supportedLanguages = Array(model.supportedLanguages)
            
            // Create dynamic language mapping
            var mapping: [String: String] = [:]
            for language in supportedLanguages {
                let code = language.languageCode?.identifier ?? ""
                if !code.isEmpty {
                    let displayName = getDisplayName(for: language)
                    mapping[code] = displayName
                }
            }
            languageMapping = mapping
            
        } catch {
            errorMessage = "Failed to load languages: \(error.localizedDescription)"
        }
        
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
    
    func getLanguageCodeForDisplayName(_ displayName: String) -> String? {
        // Find the language code for a given display name
        for language in supportedLanguages {
            if getDisplayName(for: language) == displayName {
                return language.languageCode?.identifier ?? ""
            }
        }
        return nil
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
        
        // Fallback to first supported language or "English"
        return supportedLanguages.first.map { getDisplayName(for: $0) } ?? "English"
    }
}