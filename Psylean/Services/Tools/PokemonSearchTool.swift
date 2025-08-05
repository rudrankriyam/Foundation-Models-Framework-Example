//
//  PokemonSearchTool.swift
//  Psylean
//
//  Created by Rudrank Riyam on 26/06/25.
//

import Foundation
import FoundationModels

/// A tool that searches for Pokemon and returns data for the best match
struct PokemonSearchTool: Tool {
    let name = "searchAndAnalyzePokemon"
    let description = "Searches for Pokemon based on criteria and returns detailed data for the best match"
    
    @Generable
    struct Arguments {
        @Guide(description: "The search query - can be a type, characteristics, or description like 'cute grass pokemon' or 'fierce dragon'")
        let query: String
    }
    
    func call(arguments: Arguments) async throws -> some PromptRepresentable {
        let query = arguments.query.lowercased()
        
        
        var pokemonList: [String] = []
        var selectedPokemon: String
        
        // Extract type from query if present
        let types = ["fire", "water", "grass", "electric", "psychic", "dragon", "dark", "fighting", "flying", "poison", "ground", "rock", "bug", "ghost", "steel", "ice", "normal", "fairy"]
        let detectedType = types.first { query.contains($0) }
        
        // Get Pokemon list based on type
        if let type = detectedType {
            do {
                pokemonList = try await PokeAPIClient.fetchPokemonByType(type)
            } catch {
                pokemonList = getPopularPokemon()
            }
        } else {
            pokemonList = getPopularPokemon()
        }
        
        // Select best match based on characteristics
        if query.contains("cute") || query.contains("adorable") {
            selectedPokemon = pokemonList.first { ["pikachu", "eevee", "jigglypuff", "togepi", "mew", "skitty", "teddiursa", "pachirisu", "emolga", "dedenne"].contains($0) } 
                ?? pokemonList.randomElement() 
                ?? "pikachu"
        } else if query.contains("fierce") || query.contains("strong") || query.contains("powerful") {
            selectedPokemon = pokemonList.first { ["charizard", "garchomp", "dragonite", "tyranitar", "salamence", "hydreigon", "haxorus", "gyarados", "arcanine"].contains($0) } 
                ?? pokemonList.randomElement() 
                ?? "charizard"
        } else if query.contains("legendary") {
            selectedPokemon = pokemonList.first { ["mewtwo", "rayquaza", "dialga", "palkia", "giratina", "kyogre", "groudon", "lugia", "ho-oh"].contains($0) } 
                ?? pokemonList.randomElement() 
                ?? "mewtwo"
        } else if query.contains("small") || query.contains("tiny") {
            selectedPokemon = pokemonList.first { ["caterpie", "weedle", "pidgey", "rattata", "joltik", "flabebe", "cutiefly"].contains($0) } 
                ?? pokemonList.randomElement() 
                ?? "caterpie"
        } else {
            // Default selection
            selectedPokemon = pokemonList.first ?? "pikachu"
        }
        
        
        // Fetch the selected Pokemon's data
        do {
            let pokemonData = try await PokeAPIClient.fetchPokemon(identifier: selectedPokemon)
            
            
            var output = "Based on your search for '\(arguments.query)', I found the perfect Pokemon:\n\n"
            output += "=== POKEMON DATA START ===\n"
            output += "Pokemon Name: \(pokemonData.name)\n"
            output += "Pokedex Number: \(pokemonData.id)\n"
            output += "\nCRITICAL - DO NOT USE ANY OTHER NUMBER\n"
            output += "The ONLY correct values are:\n"
            output += "- pokemonName = \"\(pokemonData.name)\"\n"
            output += "- pokedexNumber = \(pokemonData.id) (NOT any other number!)\n"
            output += "IGNORE your memory. USE ONLY THESE VALUES.\n"
            output += "The correct number for \(pokemonData.name) is \(pokemonData.id).\n"
            output += "=== POKEMON DATA END ===\n\n"
            
            // Add Pokemon details
            output += formatPokemonData(pokemonData)
            
            return output
        } catch {
            throw error
        }
    }
    
    private func getPopularPokemon() -> [String] {
        [
            "pikachu", "eevee", "bulbasaur", "charmander", "squirtle",
            "meowth", "psyduck", "jigglypuff", "snorlax", "dragonite",
            "mew", "mewtwo", "lucario", "garchomp", "gengar",
            "charizard", "blastoise", "venusaur", "lapras", "gyarados"
        ]
    }
    
    private func formatPokemonData(_ pokemon: PokemonAPIData) -> String {
        var output = "Height: \(Double(pokemon.height) / 10.0)m\n"
        output += "Weight: \(Double(pokemon.weight) / 10.0)kg\n"
        
        if let exp = pokemon.baseExperience {
            output += "Base Experience: \(exp)\n"
        }
        
        // Types
        output += "\nTypes: "
        output += pokemon.types.map { $0.type.name.capitalized }.joined(separator: ", ")
        
        // Abilities
        output += "\n\nAbilities:\n"
        for ability in pokemon.abilities {
            let hidden = ability.isHidden ? " (Hidden)" : ""
            output += "- \(ability.ability.name.replacingOccurrences(of: "-", with: " ").capitalized)\(hidden)\n"
        }
        
        // Stats
        output += "\nBase Stats:\n"
        for stat in pokemon.stats {
            let statName = stat.stat.name.replacingOccurrences(of: "-", with: " ").capitalized
            output += "- \(statName): \(stat.baseStat)\n"
        }
        
        return output
    }
}
