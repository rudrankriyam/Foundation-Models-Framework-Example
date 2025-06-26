//
//  QuickPokemonIntents.swift
//  Psylean
//
//  Created by Rudrank Riyam on 26/06/25.
//

import AppIntents

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
        "Mewtwo", "Mew", "Articuno", "Zapdos", "Moltres",
        "Lugia", "Ho-Oh", "Celebi", "Kyogre", "Groudon",
        "Rayquaza", "Dialga", "Palkia", "Giratina", "Arceus"
    ]
    
    func perform() async throws -> some IntentResult & ShowsSnippetView & ProvidesDialog {
        let intent = AnalyzePokemonIntent()
        intent.pokemonQuery = legendaryPokemon.randomElement() ?? "Mewtwo"
        return try await intent.perform()
    }
}