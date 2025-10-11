//
//  Color+Pokemon.swift
//  Psylean
//
//  Created by Rudrank Riyam on 26/06/25.
//

import SwiftUI

extension Color {
    private static let pokemonTypeColors: [String: Color] = [
        "fire": .red,
        "water": .blue,
        "grass": .green,
        "electric": .yellow,
        "psychic": .purple,
        "ice": .cyan,
        "dragon": .indigo,
        "dark": .black,
        "fairy": .pink,
        "fighting": .orange,
        "poison": .purple,
        "ground": .brown,
        "flying": .mint,
        "bug": .green,
        "rock": .gray,
        "ghost": Color.purple.opacity(0.7),
        "steel": .gray,
        "normal": .gray
    ]

    static func pokemonType(_ type: String) -> Color {
        let normalizedType = type.lowercased()
        return pokemonTypeColors[normalizedType] ?? .gray
    }
}
