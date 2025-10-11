//
//  PokemonDataTool.swift
//  Psylean
//
//  Created by Rudrank Riyam on 26/06/25.
//

import Foundation
import FoundationModels

/// A tool that fetches Pokemon data from the free PokeAPI
@Observable
final class PokemonDataTool: Tool {
    let name = "fetchPokemonData"
    let description = "Fetches detailed Pokemon information including stats, abilities, and types"

    @MainActor var fetchHistory: [PokemonFetch] = []

    @Generable
    struct Arguments {
        @Guide(description: "The Pokemon name or ID to fetch (e.g., 'pikachu' or '25')")
        let identifier: String

        @Guide(description: "Whether to fetch evolution chain data")
        let includeEvolutions: Bool
    }

    struct PokemonFetch: Identifiable {
        let id = UUID()
        let pokemonName: String
        let timestamp: Date
        let success: Bool
    }

    @MainActor func recordFetch(pokemonName: String, success: Bool) {
        fetchHistory.append(PokemonFetch(
            pokemonName: pokemonName,
            timestamp: Date(),
            success: success
        ))
    }

    func call(arguments: Arguments) async throws -> some PromptRepresentable {
        do {
            let pokemonData = try await PokeAPIClient.fetchPokemon(identifier: arguments.identifier)
            await recordFetch(pokemonName: pokemonData.name, success: true)

            var output = formatPokemonData(pokemonData)

            if arguments.includeEvolutions {
                do {
                    let evolutionChain = try await PokeAPIClient.fetchEvolutionChain(from: pokemonData.species.url)
                    output += "\n\n" + formatEvolutionChain(evolutionChain)
                } catch {
                    output += "\n\nEvolution Chain: Unable to fetch evolution data."
                }
            }

            return output
        } catch {
            await recordFetch(pokemonName: arguments.identifier, success: false)
            throw error
        }
    }

    private func formatPokemonData(_ pokemon: PokemonAPIData) -> String {
        var output = "=== POKEMON DATA START ===\n"
        output += "Pokemon Name: \(pokemon.name)\n"
        output += "Pokedex Number: \(pokemon.id)\n"
        output += "\nCRITICAL - DO NOT USE ANY OTHER NUMBER\n"
        output += "The ONLY correct values are:\n"
        output += "- pokemonName = \"\(pokemon.name)\"\n"
        output += "- pokedexNumber = \(pokemon.id) (NOT any other number!)\n"
        output += "\nIGNORE your memory. USE ONLY THESE VALUES.\n"
        output += "If you think \(pokemon.name) has a different number, YOU ARE WRONG.\n"
        output += "The correct number for \(pokemon.name) is \(pokemon.id).\n"
        output += "=== POKEMON DATA END ===\n\n"

        // Basic Info
        output += "Height: \(Double(pokemon.height) / 10.0)m\n"
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

    private func formatEvolutionChain(_ evolution: EvolutionChain) -> String {
        var output = "Evolution Chain:\n"

        func formatChainLink(_ link: EvolutionChain.ChainLink, level: Int = 0) -> String {
            let indent = String(repeating: "  ", count: level)
            var result = "\(indent)→ \(link.species.name.capitalized)\n"

            for evolution in link.evolvesTo {
                result += formatChainLink(evolution, level: level + 1)
            }

            return result
        }

        output += formatChainLink(evolution.chain)
        return output
    }
}
