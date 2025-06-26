//
//  PokeAPIClient.swift
//  Psylean
//
//  Created by Rudrank Riyam on 26/06/25.
//

import Foundation

/// Client for interacting with the PokeAPI
struct PokeAPIClient {
    static let shared = PokeAPIClient()
    
    private let baseURL = "pokeapi.co"
    private let apiVersion = "v2"
    private let session = URLSession.shared
    
    private init() {}
    
    /// Fetches Pokemon data for the given identifier
    func fetchPokemon(identifier: String) async throws -> PokemonAPIData {
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
    func fetchEvolutionChain(from speciesURL: String) async throws -> EvolutionChain {
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
}

// MARK: - Error Types

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case pokemonNotFound(String)
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