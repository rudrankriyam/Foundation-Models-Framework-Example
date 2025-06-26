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
    
    struct PokemonAPIData: Codable {
        let id: Int
        let name: String
        let height: Int
        let weight: Int
        let baseExperience: Int?
        let sprites: Sprites
        let types: [TypeElement]
        let abilities: [AbilityElement]
        let stats: [StatElement]
        
        struct Sprites: Codable {
            let frontDefault: String?
            let other: Other?
            
            struct Other: Codable {
                let officialArtwork: OfficialArtwork?
                
                enum CodingKeys: String, CodingKey {
                    case officialArtwork = "official-artwork"
                }
                
                struct OfficialArtwork: Codable {
                    let frontDefault: String?
                    
                    enum CodingKeys: String, CodingKey {
                        case frontDefault = "front_default"
                    }
                }
            }
            
            enum CodingKeys: String, CodingKey {
                case frontDefault = "front_default"
                case other
            }
        }
        
        struct TypeElement: Codable {
            let type: NamedResource
        }
        
        struct AbilityElement: Codable {
            let ability: NamedResource
            let isHidden: Bool
            
            enum CodingKeys: String, CodingKey {
                case ability
                case isHidden = "is_hidden"
            }
        }
        
        struct StatElement: Codable {
            let baseStat: Int
            let stat: NamedResource
            
            enum CodingKeys: String, CodingKey {
                case baseStat = "base_stat"
                case stat
            }
        }
        
        struct NamedResource: Codable {
            let name: String
            let url: String
        }
        
        enum CodingKeys: String, CodingKey {
            case id, name, height, weight, sprites, types, abilities, stats
            case baseExperience = "base_experience"
        }
    }
    
    @MainActor func recordFetch(pokemonName: String, success: Bool) {
        fetchHistory.append(PokemonFetch(
            pokemonName: pokemonName,
            timestamp: Date(),
            success: success
        ))
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        do {
            let pokemonData = try await fetchPokemon(identifier: arguments.identifier)
            await recordFetch(pokemonName: pokemonData.name, success: true)
            
            var output = formatPokemonData(pokemonData)
            
            if arguments.includeEvolutions {
                // For simplicity, we'll add a note about evolution
                output += "\n\nEvolution Chain: Check the Pokemon's species for evolution details."
            }
            
            return ToolOutput(output)
        } catch {
            await recordFetch(pokemonName: arguments.identifier, success: false)
            throw error
        }
    }
    
    private func fetchPokemon(identifier: String) async throws -> PokemonAPIData {
        let urlString = "https://pokeapi.co/api/v2/pokemon/\(identifier.lowercased())"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(PokemonAPIData.self, from: data)
    }
    
    private func formatPokemonData(_ pokemon: PokemonAPIData) -> String {
        var output = "Pokemon: \(pokemon.name.capitalized) (#\(pokemon.id))\n\n"
        
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
        
        // Image URL
        if let imageUrl = pokemon.sprites.other?.officialArtwork?.frontDefault {
            output += "\nOfficial Artwork: \(imageUrl)"
        }
        
        return output
    }
}
