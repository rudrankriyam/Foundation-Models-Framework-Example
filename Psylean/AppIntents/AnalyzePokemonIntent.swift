//
//  AnalyzePokemonIntent.swift
//  Psylean
//
//  Created by Rudrank Riyam on 26/06/25.
//

import AppIntents
import SwiftUI
import FoundationModels

struct AnalyzePokemonIntent: AppIntent {
    static var title: LocalizedStringResource = "Analyze Pokemon"
    static var description = IntentDescription("Get detailed information about a Pokemon by name or description")
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Pokemon", description: "Enter a Pokemon name or description (e.g., 'Pikachu' or 'cute grass pokemon')")
    var pokemonQuery: String
    
    @MainActor
    func perform() async throws -> some IntentResult & ShowsSnippetView {
        // Validate input
        guard !pokemonQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw IntentError.emptyInput
        }
        
        // Sanitize input
        let sanitizedQuery = pokemonQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9\\s-]", with: "", options: .regularExpression)
        
        guard sanitizedQuery.count >= 2 else {
            throw IntentError.inputTooShort
        }
        
        let analyzer = PokemonAnalyzer()
        
        do {
            let basicInfo = try await analyzer.getPokemonBasicInfo(sanitizedQuery)
            
            let name = basicInfo.name
            let number = basicInfo.number
            let types = basicInfo.types
            
            // Debug logging
            print("DEBUG: Pokemon basic info - Name: \(name), Number: \(number), Types: \(types)")
            
            // Validate results
            guard number > 0 && number <= 1025 else { // Current max Pokedex number
                print("DEBUG: Invalid Pokemon number: \(number)")
                throw IntentError.invalidPokemonData
            }
            
            let snippetView = PokemonSnippetView(
                name: name,
                number: number,
                types: types
            )
            
            return .result(view: snippetView)
        } catch let error as IntentError {
            throw error
        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            throw IntentError.contextWindowExceeded
        } catch {
            throw IntentError.analysisError(error.localizedDescription)
        }
    }
}

enum IntentError: LocalizedError {
    case emptyInput
    case inputTooShort
    case noAnalysisAvailable
    case incompleteAnalysis
    case invalidPokemonData
    case contextWindowExceeded
    case analysisError(String)
    
    var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Please enter a Pokemon name or description"
        case .inputTooShort:
            return "Input too short. Please enter at least 2 characters"
        case .noAnalysisAvailable:
            return "No Pokemon analysis was generated"
        case .incompleteAnalysis:
            return "Pokemon analysis is incomplete. Please try again"
        case .invalidPokemonData:
            return "Invalid Pokemon data received. Please try again"
        case .contextWindowExceeded:
            return "Request too complex. Please try a simpler query"
        case .analysisError(let message):
            return "Analysis failed: \(message)"
        }
    }
}