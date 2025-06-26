//
//  QuickPokemonIntents.swift
//  Psylean
//
//  Created by Rudrank Riyam on 26/06/25.
//

import AppIntents
import Foundation
import SwiftUI
import FoundationModels

// Quick intent for Pikachu
struct QuickPikachuIntent: AppIntent {
    static var title: LocalizedStringResource = "Show Pikachu"
    static var description = IntentDescription("Quickly get information about Pikachu")
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ShowsSnippetView & ProvidesDialog {
        let intent = AnalyzePokemonIntent()
        intent.pokemonQuery = "Pikachu"
        return try await intent.perform()
    }
}

// Quick intent for today's featured Pokemon
struct RandomPokemonIntent: AppIntent {
    static var title: LocalizedStringResource = "Random Pokemon"
    static var description = IntentDescription("Discover a random Pokemon")
    static var openAppWhenRun: Bool = false
    
    private let randomPokemon = [
        "Pikachu", "Charizard", "Mewtwo", "Eevee", "Gengar",
        "Lucario", "Garchomp", "Greninja", "Umbreon", "Dragonite",
        "Gyarados", "Snorlax", "Alakazam", "Machamp", "Lapras"
    ]
    
    func perform() async throws -> some IntentResult & ShowsSnippetView & ProvidesDialog {
        let intent = AnalyzePokemonIntent()
        intent.pokemonQuery = randomPokemon.randomElement() ?? "Pikachu"
        return try await intent.perform()
    }
}

// Quick intent for legendary Pokemon
struct LegendaryPokemonIntent: AppIntent {
    static var title: LocalizedStringResource = "Find Legendary Pokemon"
    static var description = IntentDescription("Search for a legendary Pokemon")
    static var openAppWhenRun: Bool = false
    
    private let legendaryPokemon = [
        // Gen 1
        "Articuno", "Zapdos", "Moltres", "Mewtwo",
        // Gen 2
        "Raikou", "Entei", "Suicune", "Lugia", "Ho-Oh",
        // Gen 3
        "Regirock", "Regice", "Registeel", "Latias", "Latios",
        "Kyogre", "Groudon", "Rayquaza",
        // Gen 4
        "Uxie", "Mesprit", "Azelf", "Dialga", "Palkia",
        "Heatran", "Regigigas", "Giratina", "Cresselia",
        // Gen 5
        "Cobalion", "Terrakion", "Virizion", "Tornadus",
        "Thundurus", "Reshiram", "Zekrom", "Landorus", "Kyurem",
        // Gen 6
        "Xerneas", "Yveltal", "Zygarde",
        // Gen 7
        "Tapu Koko", "Tapu Lele", "Tapu Bulu", "Tapu Fini",
        "Solgaleo", "Lunala", "Necrozma",
        // Gen 8
        "Zacian", "Zamazenta", "Eternatus", "Kubfu", "Urshifu",
        "Regieleki", "Regidrago", "Glastrier", "Spectrier", "Calyrex",
        // Gen 9
        "Koraidon", "Miraidon", "Wo-Chien", "Chien-Pao",
        "Ting-Lu", "Chi-Yu", "Ogerpon", "Terapagos"
    ]
    
    func perform() async throws -> some IntentResult & ShowsSnippetView & ProvidesDialog {
        let selectedLegendary = legendaryPokemon.randomElement() ?? "Mewtwo"
        
        // Directly fetch Pokemon data from the API
        do {
            let pokemonData = try await PokeAPIClient.fetchPokemon(identifier: selectedLegendary.lowercased())
            
            // Extract types
            let types = pokemonData.types.map { $0.type.name.capitalized }
            
            // Create description
            let description = "The legendary \(types.joined(separator: "/")) type Pokemon, \(pokemonData.name.capitalized) stands at \(Double(pokemonData.height) / 10.0)m tall and possesses incredible power."
            
            // Download image
            let imageURL = URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/\(pokemonData.id).png")!
            let imageData: Data? = await downloadImageWithRetry(from: imageURL, maxRetries: 3)
            
            let snippetView = PokemonSnippetView(
                name: pokemonData.name.capitalized,
                number: pokemonData.id,
                types: types,
                description: description,
                imageData: imageData
            )
            
            // Create a voice-friendly response
            let typeString = types.count > 1 ? "\(types[0]) and \(types[1])" : types.first ?? ""
            let voiceResponse = "Found \(pokemonData.name.capitalized), a \(typeString) type legendary Pokemon!"
            
            return .result(
                dialog: IntentDialog(stringLiteral: voiceResponse),
                view: snippetView
            )
        } catch {
            throw IntentError.analysisError("Failed to fetch legendary Pokemon data")
        }
    }
    
    private func downloadImageWithRetry(from url: URL, maxRetries: Int) async -> Data? {
        for attempt in 1...maxRetries {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 {
                    return data
                }
            } catch {
                if attempt < maxRetries {
                    try? await Task.sleep(nanoseconds: UInt64(attempt) * 500_000_000)
                }
            }
        }
        return nil
    }
}
