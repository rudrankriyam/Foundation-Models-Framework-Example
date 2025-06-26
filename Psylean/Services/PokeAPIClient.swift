//
//  PokeAPIClient.swift
//  Psylean
//
//  Created by Rudrank Riyam on 26/06/25.
//

import Foundation

/// Client for interacting with the PokeAPI
struct PokeAPIClient {
    private static let baseURL = "pokeapi.co"
    private static let apiVersion = "v2"
    private static let session = URLSession.shared
    
    /// Fetches Pokemon data for the given identifier
    static func fetchPokemon(identifier: String) async throws -> PokemonAPIData {
        var components = URLComponents()
        components.scheme = "https"
        components.host = baseURL
        components.path = "/api/\(apiVersion)/pokemon/\(identifier.lowercased())"
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(PokemonAPIData.self, from: data)
        case 404:
            throw APIError.pokemonNotFound(identifier)
        case 429:
            throw APIError.rateLimited
        default:
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
    }
    
    /// Fetches evolution chain for a species URL
    static func fetchEvolutionChain(from speciesURL: String) async throws -> EvolutionChain {
        guard let url = URL(string: speciesURL) else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await session.data(from: url)
        let species = try JSONDecoder().decode(PokemonSpecies.self, from: data)
        
        guard let evolutionURL = URL(string: species.evolutionChain.url) else {
            throw APIError.invalidURL
        }
        
        let (evolutionData, _) = try await session.data(from: evolutionURL)
        return try JSONDecoder().decode(EvolutionChain.self, from: evolutionData)
    }
    
    /// Fetches Pokemon by type
    static func fetchPokemonByType(_ type: String) async throws -> [String] {
        var components = URLComponents()
        components.scheme = "https"
        components.host = baseURL
        components.path = "/api/\(apiVersion)/type/\(type.lowercased())"
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            let typeData = try JSONDecoder().decode(TypeData.self, from: data)
            return typeData.pokemon.map { $0.pokemon.name }
        case 404:
            throw APIError.typeNotFound(type)
        default:
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
    }
}

// MARK: - Error Types

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case pokemonNotFound(String)
    case typeNotFound(String)
    case rateLimited
    case httpError(statusCode: Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .pokemonNotFound(let identifier):
            return "Pokemon '\(identifier)' not found"
        case .typeNotFound(let type):
            return "Type '\(type)' not found"
        case .rateLimited:
            return "API rate limit exceeded. Please try again later"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        }
    }
}

// MARK: - API Models

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
    let species: NamedResource
    
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
        case id, name, height, weight, sprites, types, abilities, stats, species
        case baseExperience = "base_experience"
    }
}

// MARK: - Evolution Models

struct PokemonSpecies: Codable {
    let evolutionChain: EvolutionChainLink
    
    struct EvolutionChainLink: Codable {
        let url: String
    }
    
    enum CodingKeys: String, CodingKey {
        case evolutionChain = "evolution_chain"
    }
}

struct EvolutionChain: Codable {
    let chain: ChainLink
    
    struct ChainLink: Codable {
        let species: NamedResource
        let evolvesTo: [ChainLink]
        
        struct NamedResource: Codable {
            let name: String
            let url: String
        }
        
        enum CodingKeys: String, CodingKey {
            case species
            case evolvesTo = "evolves_to"
        }
    }
}

// MARK: - Type Models

struct TypeData: Codable {
    let pokemon: [PokemonEntry]
    
    struct PokemonEntry: Codable {
        let pokemon: NamedResource
        
        struct NamedResource: Codable {
            let name: String
            let url: String
        }
    }
}