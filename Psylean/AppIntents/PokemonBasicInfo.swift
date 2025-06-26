//
//  PokemonBasicInfo.swift
//  Psylean
//
//  Created by Rudrank Riyam on 26/06/25.
//

import Foundation
import FoundationModels

@Generable
struct PokemonBasicInfo: Equatable {
    @Guide(description: "The Pokemon's name")
    let name: String
    
    @Guide(description: "The Pokemon's Pokedex number")
    let number: Int
    
    @Guide(description: "The Pokemon's types (e.g., Water, Flying)")
    let types: [String]
}