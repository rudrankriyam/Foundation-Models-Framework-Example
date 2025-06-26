//
//  AnalyzePokemonIntent.swift
//  FoundationLab
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
        let analyzer = SimplePokemonAnalyzer()
        
        do {
            let result = try await analyzer.analyzePokemon(pokemonQuery)
            
            let snippetView = PokemonSnippetView(
                name: result.name,
                number: result.number,
                types: result.types
            )
            
            return .result(view: snippetView)
        } catch {
            throw IntentError.analysisError(error.localizedDescription)
        }
    }
}

struct SimplePokemonAnalyzer {
    struct PokemonResult {
        let name: String
        let number: Int
        let types: [String]
    }
    
    func analyzePokemon(_ query: String) async throws -> PokemonResult {
        let session = LanguageModelSession(
            instructions: Instructions(
                "You are a Pokemon expert. When given a Pokemon name or description, provide the exact Pokemon data. " +
                "For descriptions like 'cute grass pokemon', identify the most fitting Pokemon. " +
                "Always return valid Pokemon data with accurate Pokedex numbers."
            )
        )
        
        let response = try await session.respond(
            to: Prompt("""
                Identify this Pokemon: \(query)
                Return the Pokemon's name, Pokedex number, and types.
                If it's a description, choose the most iconic Pokemon that matches.
                """),
            generating: PokemonData.self
        )
        
        return PokemonResult(
            name: response.content.name,
            number: response.content.pokedexNumber,
            types: response.content.types
        )
    }
}

@Generable
struct PokemonData {
    @Guide(description: "The Pokemon's name")
    let name: String
    
    @Guide(description: "The Pokemon's Pokedex number")
    let pokedexNumber: Int
    
    @Guide(description: "The Pokemon's types", .count(1...2))
    let types: [String]
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