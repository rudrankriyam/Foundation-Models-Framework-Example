//
//  PokemonQueryProvider.swift
//  Psylean
//
//  Created by Rudrank Riyam on 26/06/25.
//

import AppIntents

struct PokemonQueryProvider: DynamicOptionsProvider {
    // Popular Pokemon that users frequently search for
    static let popularPokemon = [
        "Pikachu",
        "Charizard",
        "Mewtwo",
        "Eevee",
        "Gengar",
        "Lucario",
        "Garchomp",
        "Greninja",
        "Umbreon",
        "Dragonite",
        "Gyarados",
        "Snorlax"
    ]

    // Common descriptive queries
    static let descriptiveQueries = [
        "cute grass pokemon",
        "legendary dragon",
        "fire starter",
        "water starter",
        "grass starter",
        "electric mouse",
        "psychic legendary",
        "ghost type",
        "fastest pokemon",
        "strongest pokemon"
    ]

    func results() async throws -> [String] {
        // Combine popular Pokemon and descriptive queries
        return Self.popularPokemon + Self.descriptiveQueries
    }

    func defaultResult() async -> String? {
        return nil
    }
}
