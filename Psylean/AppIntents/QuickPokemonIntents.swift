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
        let intent = AnalyzePokemonIntent()
        intent.pokemonQuery = legendaryPokemon.randomElement() ?? "Mewtwo"
        return try await intent.perform()
    }
}