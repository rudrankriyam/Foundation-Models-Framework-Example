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
    
    @Guide(description: "A brief, engaging description of the Pokemon")
    let description: String
}

// Extended version with image data
struct PokemonBasicInfoWithImage: Equatable {
    let name: String
    let number: Int
    let types: [String]
    let description: String
    let imageData: Data?
    
    init(from basicInfo: PokemonBasicInfo, imageData: Data? = nil) {
        self.name = basicInfo.name
        self.number = basicInfo.number
        self.types = basicInfo.types
        self.description = basicInfo.description
        self.imageData = imageData
    }
}