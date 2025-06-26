//
//  PokemonAnalysis.swift
//  Psylean
//
//  Created by Rudrank Riyam on 26/06/25.
//

import Foundation
import FoundationModels

/// A comprehensive Pokemon analysis with beautiful streaming support
@Generable
struct PokemonAnalysis: Equatable {
    @Guide(description: "An epic title for this Pokemon analysis")
    let title: String
    
    @Guide(description: "The Pokemon's name")
    let pokemonName: String
    
    @Guide(description: "The Pokemon's Pokedex number")
    let pokedexNumber: Int
    
    @Guide(description: "A poetic description of the Pokemon's essence")
    let poeticDescription: String
    
    @Guide(description: "Primary and secondary types")
    let types: [PokemonType]
    
    @Guide(description: "Battle role classification")
    let battleRole: BattleRole
    
    @Guide(description: "Detailed stat analysis")
    let statAnalysis: StatAnalysis
    
    @Guide(description: "Notable abilities and their strategic uses", .count(2...3))
    let abilities: [AbilityAnalysis]
    
    @Guide(description: "Strength matchups against other types", .count(3...5))
    let strengths: [TypeMatchup]
    
    @Guide(description: "Weakness matchups against other types", .count(3...5))
    let weaknesses: [TypeMatchup]
    
    @Guide(description: "Recommended moves for competitive play", .count(4))
    let recommendedMoves: [String]
    
    @Guide(description: "Overall competitive tier rating")
    let competitiveTier: CompetitiveTier
    
    @Guide(description: "Fun facts and trivia about this Pokemon", .count(2...3))
    let funFacts: [String]
    
    @Guide(description: "A legendary quote about this Pokemon")
    let legendaryQuote: String
}

@Generable
struct PokemonType: Equatable {
    var id = GenerationID()
    
    @Guide(description: "The type name (Fire, Water, Grass, etc.)")
    let name: String
    
    @Guide(description: "A color representing this type")
    let colorDescription: String
}

@Generable
enum BattleRole: String {
    case physicalAttacker = "Physical Attacker"
    case specialAttacker = "Special Attacker"
    case tank = "Tank"
    case speedster = "Speedster"
    case support = "Support"
    case mixedAttacker = "Mixed Attacker"
    case wall = "Defensive Wall"
}

@Generable
struct StatAnalysis: Equatable {
    @Guide(description: "Total base stat sum")
    let totalStats: Int
    
    @Guide(description: "Highest stat category")
    let strongestStat: String
    
    @Guide(description: "Lowest stat category")
    let weakestStat: String
    
    @Guide(description: "Overall stat distribution analysis")
    let distributionAnalysis: String
    
    @Guide(description: "Battle strategy based on stats")
    let battleStrategy: String
}

@Generable
struct AbilityAnalysis: Equatable {
    var id = GenerationID()
    
    @Guide(description: "The ability name")
    let name: String
    
    @Guide(description: "Whether this is a hidden ability")
    let isHidden: Bool
    
    @Guide(description: "Strategic use in battle")
    let strategicUse: String
    
    @Guide(description: "Synergy rating 1-10", .range(1...10))
    let synergyRating: Int
}

@Generable
struct TypeMatchup: Equatable {
    var id = GenerationID()
    
    @Guide(description: "The opposing type")
    let type: String
    
    @Guide(description: "Effectiveness multiplier (0.5, 2.0, etc.)")
    let effectiveness: Double
    
    @Guide(description: "Strategic tip for this matchup")
    let tip: String
}

@Generable
enum CompetitiveTier: String {
    case ubers = "Ubers"
    case overUsed = "OU (OverUsed)"
    case underUsed = "UU (UnderUsed)"
    case rarelyUsed = "RU (RarelyUsed)"
    case neverUsed = "NU (NeverUsed)"
    case littleCup = "LC (Little Cup)"
}