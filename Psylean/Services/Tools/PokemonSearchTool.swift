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
            pokemonList = try await fetchPokemonByType(type: type.lowercased())
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
    
    private func fetchPokemonByType(type: String) async throws -> [String] {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "pokeapi.co"
        components.path = "/api/v2/type/\(type)"
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            // If type not found, return empty list
            return []
        }
        
        let typeData = try JSONDecoder().decode(TypeData.self, from: data)
        return typeData.pokemon.map { $0.pokemon.name }
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

// MARK: - Type API Model

private struct TypeData: Codable {
    let pokemon: [PokemonEntry]
    
    struct PokemonEntry: Codable {
        let pokemon: NamedResource
        
        struct NamedResource: Codable {
            let name: String
            let url: String
        }
    }
}