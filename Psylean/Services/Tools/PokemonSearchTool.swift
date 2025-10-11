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
        @Guide(
            description: """
            The search query - can be a type, characteristics, or description like 'cute grass pokemon'
            or 'fierce dragon'
            """
        )
        let query: String
    }

    func call(arguments: Arguments) async throws -> some PromptRepresentable {
        let query = arguments.query.lowercased()
        let pokemonList = await fetchPokemonList(for: query)
        let selectedPokemon = choosePokemon(from: pokemonList, query: query)

        do {
            let pokemonData = try await PokeAPIClient.fetchPokemon(identifier: selectedPokemon)
            let output = buildAnalysisOutput(for: pokemonData, originalQuery: arguments.query)
            return output
        } catch {
            throw error
        }
    }

    private func fetchPokemonList(for query: String) async -> [String] {
        let types = [
            "fire", "water", "grass", "electric", "psychic",
            "dragon", "dark", "fighting", "flying", "poison",
            "ground", "rock", "bug", "ghost", "steel",
            "ice", "normal", "fairy"
        ]

        if let type = types.first(where: { query.contains($0) }) {
            do {
                return try await PokeAPIClient.fetchPokemonByType(type)
            } catch {
                return getPopularPokemon()
            }
        }

        return getPopularPokemon()
    }

    private func choosePokemon(from list: [String], query: String) -> String {
        if query.contains("cute") || query.contains("adorable") {
            let cuteOptions = [
                "pikachu", "eevee", "jigglypuff", "togepi", "mew",
                "skitty", "teddiursa", "pachirisu", "emolga", "dedenne"
            ]
            return list.first { cuteOptions.contains($0) }
                ?? list.randomElement()
                ?? "pikachu"
        }

        if query.contains("fierce") || query.contains("strong") || query.contains("powerful") {
            let powerfulOptions = [
                "charizard", "garchomp", "dragonite", "tyranitar", "salamence",
                "hydreigon", "haxorus", "gyarados", "arcanine"
            ]
            return list.first { powerfulOptions.contains($0) }
                ?? list.randomElement()
                ?? "charizard"
        }

        if query.contains("legendary") {
            let legendaryOptions = [
                "mewtwo", "rayquaza", "dialga", "palkia", "giratina",
                "kyogre", "groudon", "lugia", "ho-oh"
            ]
            return list.first { legendaryOptions.contains($0) }
                ?? list.randomElement()
                ?? "mewtwo"
        }

        if query.contains("small") || query.contains("tiny") {
            let smallOptions = [
                "caterpie", "weedle", "pidgey", "rattata",
                "joltik", "flabebe", "cutiefly"
            ]
            return list.first { smallOptions.contains($0) }
                ?? list.randomElement()
                ?? "caterpie"
        }

        return list.first ?? "pikachu"
    }

    private func buildAnalysisOutput(for pokemon: PokemonAPIData, originalQuery: String) -> String {
        var output = "Based on your search for '\(originalQuery)', I found the perfect Pokemon:\n\n"
        output += "=== POKEMON DATA START ===\n"
        output += "Pokemon Name: \(pokemon.name)\n"
        output += "Pokedex Number: \(pokemon.id)\n"
        output += "\nCRITICAL - DO NOT USE ANY OTHER NUMBER\n"
        output += "The ONLY correct values are:\n"
        output += "- pokemonName = \"\(pokemon.name)\"\n"
        output += "- pokedexNumber = \(pokemon.id) (NOT any other number!)\n"
        output += "IGNORE your memory. USE ONLY THESE VALUES.\n"
        output += "The correct number for \(pokemon.name) is \(pokemon.id).\n"
        output += "=== POKEMON DATA END ===\n\n"

        output += formatPokemonData(pokemon)
        return output
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
