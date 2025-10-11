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

                "SEARCH FLEXIBILITY:"
                "- Understand natural language: 'the fire starter from gen 3' → Torchic"
                "- Handle descriptions: 'yellow mouse' → Pikachu, 'spooky ghost' → Gengar"
                "- Interpret attributes: 'fastest pokemon' → search for Speed stat"
                "- Understand nicknames: 'pika' → Pikachu, 'char' → Charmander/Charizard"
                "- Handle typos: 'pikachuu', 'charzard' → correct to proper names"
                "- Understand context: 'ash's first pokemon' → Pikachu"
                "- Generation queries: 'gen 1 starters', 'kanto fire type'"

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

        let stream = session.streamResponse(
            generating: PokemonAnalysis.self,
            includeSchemaInPrompt: false,
            options: GenerationOptions(temperature: 0.1)
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
            "- types: An array of PokemonType objects based on the 'Types:' line from the data"
            "  For example, if Types: Water, Flying then create two PokemonType objects:"
            "  [{name: 'Water', colorDescription: 'Blue'}, {name: 'Flying', colorDescription: 'Light blue'}]"
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
            analysis = partialAnalysis.content
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

    /// Direct (non-streaming) analysis for App Intents
    func analyzePokemonDirect(_ identifier: String) async throws -> PokemonAnalysis {
        isAnalyzing = true
        error = nil

        defer {
            isAnalyzing = false
        }

        let result = try await session.respond(
            generating: PokemonAnalysis.self,
            includeSchemaInPrompt: false,
            options: GenerationOptions(temperature: 0.1)
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
            "- types: An array of PokemonType objects based on the 'Types:' line from the data"
            "  For example, if Types: Water, Flying then create two PokemonType objects:"
            "  [{name: 'Water', colorDescription: 'Blue'}, {name: 'Flying', colorDescription: 'Light blue'}]"
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

        return result.content
    }

    /// Get basic Pokemon info for App Intents (just name, number, types)
    func getPokemonBasicInfo(_ identifier: String) async throws -> PokemonBasicInfo {
        let result = try await session.respond(
            generating: PokemonBasicInfo.self,
            includeSchemaInPrompt: false,
            options: GenerationOptions(temperature: 0.3)
        ) {
            "Get basic info for: \(identifier)"

            "SEARCH UNDERSTANDING:"
            "- Natural language: 'the fire starter from gen 3' → find Torchic"
            "- Descriptions: 'yellow mouse', 'red dragon' → identify the matching Pokemon"
            "- Nicknames/shortcuts: 'pika', 'zard' → expand to full names"
            "- Typos: 'pikachuu', 'bulbsaur' → correct automatically"
            "- Context clues: 'ash's buddy', 'team rocket's cat' → understand references"
            "- Attributes: 'fastest', 'strongest psychic' → search by stats/type"

            "Instructions:"
            "1. Interpret the query flexibly - don't be too literal"
            "2. If it's descriptive or ambiguous, use searchPokemon"
            "3. If it's a clear name/ID (even with typos), use fetchPokemonData"
            "4. Return the name, number, types, and a brief description"

            "The response should contain:"
            "- name: The Pokemon's name from the tool"
            "- number: The Pokedex number from the tool"
            "- types: Array of type names (e.g., ['Water', 'Flying'])"
            "- description: A brief, engaging 1-2 sentence description that captures the Pokemon's essence"

            "For the description, make it:"
            "- Vivid and engaging"
            "- Highlight what makes this Pokemon special"
            "- Reference its appearance, abilities, or personality"
            "- Keep it concise but memorable"

            "Example: For Pikachu, return:"
            "name: 'Pikachu'"
            "number: 25"
            "types: ['Electric']"
            "description: 'The beloved electric mouse Pokemon whose adorable appearance and loyal nature have "
            "made it the most iconic Pokemon in the world.'"
        }

        return result.content
    }
}
