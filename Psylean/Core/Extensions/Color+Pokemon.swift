//
//  Color+Pokemon.swift
//  Psylean
//
//  Created by Rudrank Riyam on 26/06/25.
//

import SwiftUI

extension Color {
    static func pokemonType(_ type: String) -> Color {
        switch type.lowercased() {
        case "fire": return .red
        case "water": return .blue
        case "grass": return .green
        case "electric": return .yellow
        case "psychic": return .purple
        case "ice": return .cyan
        case "dragon": return .indigo
        case "dark": return .black
        case "fairy": return .pink
        case "fighting": return .orange
        case "poison": return .purple
        case "ground": return .brown
        case "flying": return .mint
        case "bug": return .green
        case "rock": return .gray
        case "ghost": return .purple.opacity(0.7)
        case "steel": return .gray
        case "normal": return .gray
        default: return .gray
        }
    }
}
