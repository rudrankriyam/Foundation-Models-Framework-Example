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
        let analyzer = PokemonAnalyzer()
        
        do {
            try await analyzer.analyzePokemon(pokemonQuery)
            
            guard let analysis = analyzer.analysis else {
                throw IntentError.noAnalysisAvailable
            }
            
            let name = analysis.pokemonName ?? "Unknown"
            let number = analysis.pokedexNumber ?? 0
            let types = analysis.types?.compactMap { $0.name } ?? []
            
            let snippetView = PokemonSnippetView(
                name: name,
                number: number,
                types: types
            )
            
            return .result(view: snippetView)
        } catch {
            throw IntentError.analysisError(error.localizedDescription)
        }
    }
}

enum IntentError: LocalizedError {
    case noAnalysisAvailable
    case analysisError(String)
    
    var errorDescription: String? {
        switch self {
        case .noAnalysisAvailable:
            return "No Pokemon analysis was generated"
        case .analysisError(let message):
            return "Analysis failed: \(message)"
        }
    }
}