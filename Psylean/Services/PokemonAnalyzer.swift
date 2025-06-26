//
//  PokemonAnalyzer.swift
//  Psylean
//
//  Created by Rudrank Riyam on 26/06/25.
//

import Foundation
import FoundationModels
import Observation

/// Manages streaming Pokemon analysis generation
@Observable
@MainActor
final class PokemonAnalyzer {
    private(set) var analysis: PokemonAnalysis.PartiallyGenerated?
    private var session: LanguageModelSession
    private var currentTask: Task<Void, Error>?
    
    var error: Error?
    var isAnalyzing = false
    
    init() {
        self.session = LanguageModelSession(
            tools: [PokemonDataTool(), PokemonSearchTool()],
            instructions: Instructions {
                "You are a Pokemon Professor providing deep, insightful analysis about Pokemon."
                
                "Your role is to:"
                "1. If given a description, use searchPokemon with type/characteristics"
                "2. When you get the list, call searchPokemon AGAIN with selectedPokemon parameter" 
                "3. If given a specific name/ID, use fetchPokemonData directly"
                "4. Use ONLY the pokemonName and pokedexNumber from the tool response"
                "5. Analyze the Pokemon's stats, abilities, and types comprehensively"
                "6. Provide strategic battle insights and competitive analysis"
                
                "Focus on creating an epic, engaging analysis that includes:"
                "- Poetic descriptions that capture the Pokemon's essence"
                "- Strategic battle role classification based on stats"
                "- Detailed ability analysis with synergy ratings"
                "- Type matchup strategies and tips"
                "- Competitive tier placement and move recommendations"
                "- Fun facts and legendary quotes that bring the Pokemon to life"
                
                "Be creative, insightful, and passionate about Pokemon!"
            }
        )
    }
    
    func analyzePokemon(_ identifier: String) async throws {
        // Cancel any existing analysis
        currentTask?.cancel()
        
        isAnalyzing = true
        error = nil
        
        defer {
            isAnalyzing = false
            currentTask = nil
        }
        
        // Create a new task for this analysis
        currentTask = Task {
            try await performAnalysis(identifier)
        }
        
        do {
            try await currentTask?.value
        } catch {
            if !Task.isCancelled {
                self.error = error
                throw error
            }
        }
    }
    
    private func performAnalysis(_ identifier: String) async throws {
        #if DEBUG
        print("🎯 STARTING ANALYSIS FOR: \(identifier)")
        #endif
        
        let stream = session.streamResponse(
                generating: PokemonAnalysis.self,
                options: GenerationOptions(
                    temperature: 0.1  // Very low temperature for maximum determinism
                ),
                includeSchemaInPrompt: false
            ) {
                "Analyze based on this request: \(identifier)"
                
                "For ANY request (descriptive or specific):"
                "1. If it's a description like 'cute grass pokemon', use searchAndAnalyzePokemon with the full query"
                "2. If it's a specific name like 'pikachu', use fetchPokemonData directly"
                "3. The tool will return the EXACT Pokemon data including the correct Pokedex number"
                
                "You MUST use these EXACT values:"
                "- Copy the Pokemon Name EXACTLY as shown (this goes in pokemonName)"
                "- Copy the Pokedex Number EXACTLY as shown (this goes in pokedexNumber)"

                "Then provide a comprehensive analysis including:"
                "- An epic title that captures this Pokemon's essence"
                "- pokemonName: MUST match the 'Pokemon Name' from the data section"
                "- pokedexNumber: MUST match the 'Pokedex Number' from the data section"
                "- A poetic description of what makes this Pokemon special"
                "- Battle role classification based on its stats"
                "- Detailed stat analysis with strategic insights"
                "- All abilities with strategic uses and synergy ratings"
                "- Type matchups (strengths and weaknesses) with battle tips"
                "- 4 recommended competitive moves"
                "- Competitive tier placement"
                "- Evolution chain (if available) with evolution methods and requirements"
                "- 2-3 fascinating fun facts"
                "- A legendary quote that embodies this Pokemon's spirit"

                "DO NOT:"
                "- Guess or use numbers from memory"
                "- If tool says Gengar is #94, use 94 (NOT 149 or any other number)"

                "Make it engaging, insightful, and worthy of a true Pokemon master!"
            }
            
        // Stream the partially generated response
        for try await partialAnalysis in stream {
            // Check for cancellation
            try Task.checkCancellation()
            analysis = partialAnalysis
            
            #if DEBUG
            // Log when we get the Pokemon name and number
            if let name = partialAnalysis.pokemonName, let number = partialAnalysis.pokedexNumber {
                print("🤖 AI GENERATED - Pokemon: \(name), Number: \(number)")
            }
            #endif
        }
    }
    
    func stopAnalysis() {
        currentTask?.cancel()
        isAnalyzing = false
    }
    
    func reset() {
        currentTask?.cancel()
        analysis = nil
        error = nil
        isAnalyzing = false
    }
    
    func prewarm() {
        session.prewarm()
    }
}
