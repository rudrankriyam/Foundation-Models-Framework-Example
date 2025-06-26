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
                "1. If given a description (like 'cute grass pokemon'), use searchPokemon to find matching types"
                "2. Select the most appropriate Pokemon based on the description"
                "3. Fetch detailed Pokemon data using the fetchPokemonData tool"
                "4. Analyze the Pokemon's stats, abilities, and types comprehensively"
                "5. Provide strategic battle insights and competitive analysis"
                "6. Share interesting facts and create engaging descriptions"
                
                "For descriptive searches: First use searchPokemon, then choose the best match."
                "For specific names/IDs: Use fetchPokemonData directly."
                
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
                print("Analysis Error: \(error)")
                print("Error Type: \(type(of: error))")
                if let localizedError = error as? LocalizedError {
                    print("Localized Description: \(localizedError.localizedDescription)")
                    print("Failure Reason: \(localizedError.failureReason ?? "None")")
                }
                self.error = error
                throw error
            }
        }
    }
    
    private func performAnalysis(_ identifier: String) async throws {
        let stream = session.streamResponse(
                generating: PokemonAnalysis.self,
                options: GenerationOptions(
                    temperature: 0.8,
                    maxTokens: 2000  // Limit response size
                ),
                includeSchemaInPrompt: false
            ) {
                "Analyze based on this request: \(identifier)"
                
                "If this looks like a description (contains words like 'cute', 'fierce', 'small', 'legendary', etc. with a type):"
                "1. Extract the type (fire, water, grass, etc.) from the description"
                "2. Use searchPokemon with that type to get a list"
                "3. Choose the Pokemon that best matches the characteristics"
                "4. Explain briefly why you chose this specific Pokemon"
                
                "If this is a specific name or number, fetch that Pokemon directly."
                
                "Always fetch the Pokemon's data using fetchPokemonData (include evolution data)."
                
                "Then provide a comprehensive analysis including:"
                "- An epic title that captures this Pokemon's essence"
                "- The EXACT Pokemon name and Pokedex number from the fetched data (CRITICAL: use the actual ID from the API, not a guess)"
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
                
                "Make it engaging, insightful, and worthy of a true Pokemon master!"
            }
            
        // Stream the partially generated response
        for try await partialAnalysis in stream {
            // Check for cancellation
            try Task.checkCancellation()
            analysis = partialAnalysis
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
