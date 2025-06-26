//
//  PokemonSearchTool.swift
//  Psylean
//
//  Created by Rudrank Riyam on 26/06/25.
//

import Foundation
import FoundationModels

/// A tool that searches for Pokemon based on descriptions
struct PokemonSearchTool: Tool {
    let name = "searchPokemon"
    let description = "Searches for Pokemon based on type, characteristics, or descriptions"
    
    @Generable
    struct Arguments {
        @Guide(description: "The type to filter by (optional: fire, water, grass, etc.)")
        let type: String?
        
        @Guide(description: "Additional characteristics to look for (cute, fierce, large, small, etc.)")
        let characteristics: String?
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        var pokemonList: [String] = []
        
        // If type is specified, fetch Pokemon of that type
        if let type = arguments.type {
            do {
                pokemonList = try await PokeAPIClient.fetchPokemonByType(type.lowercased())
            } catch APIError.typeNotFound {
                // If type not found, use popular Pokemon
                pokemonList = getPopularPokemon()
            } catch {
                throw error
            }
        } else {
            // Provide a curated list of popular Pokemon
            pokemonList = getPopularPokemon()
        }
        
        var output = "Available Pokemon"
        if let type = arguments.type {
            output += " of type \(type.capitalized)"
        }
        output += ":\n\n"
        
        // Add the list
        for pokemon in pokemonList.prefix(20) { // Limit to 20 to avoid overwhelming
            output += "- \(pokemon)\n"
        }
        
        if let characteristics = arguments.characteristics {
            output += "\nNote: You requested '\(characteristics)' characteristics. "
            output += "Please select a Pokemon from the list above that best matches this description."
        }
        
        return ToolOutput(output)
    }
    
    private func getPopularPokemon() -> [String] {
        [
            "pikachu", "eevee", "bulbasaur", "charmander", "squirtle",
            "meowth", "psyduck", "jigglypuff", "snorlax", "dragonite",
            "mew", "mewtwo", "lucario", "garchomp", "gengar",
            "charizard", "blastoise", "venusaur", "lapras", "gyarados"
        ]
    }
}
