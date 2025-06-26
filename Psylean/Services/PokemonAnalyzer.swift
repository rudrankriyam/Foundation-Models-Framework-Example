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
        isAnalyzing = true
        error = nil
        
        defer {
            isAnalyzing = false
        }
        
        do {
            let stream = session.streamResponse(
                generating: PokemonAnalysis.self,
                options: GenerationOptions(
                    temperature: 0.8
                ),
                includeSchemaInPrompt: false
            ) {
                "Analyze based on this request: \(identifier)"
                
                "If this looks like a description (e.g., 'cute grass pokemon', 'fierce fire type'):"
                "1. Use searchPokemon to find Pokemon matching the type/characteristics"
                "2. Choose the most fitting Pokemon based on the description"
                "3. Explain why you chose this specific Pokemon"
                
                "If this is a specific name or number, fetch that Pokemon directly."
                
                "Always fetch the Pokemon's data using fetchPokemonData (include evolution data)."
                
                "Then provide a comprehensive analysis including:"
                "- An epic title that captures this Pokemon's essence"
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
                analysis = partialAnalysis
            }
            
        } catch {
            self.error = error
            throw error
        }
    }
    
    func reset() {
        analysis = nil
        error = nil
        isAnalyzing = false
    }
    
    func prewarm() {
        session.prewarm()
    }
}
