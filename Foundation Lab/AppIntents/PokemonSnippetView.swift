//
//  PokemonSnippetView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 26/06/25.
//

import SwiftUI

struct PokemonSnippetView: View {
    let name: String
    let number: Int
    let types: [String]
    
    var body: some View {
        VStack(spacing: 12) {
            AsyncImage(url: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/\(number).png")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
            } placeholder: {
                ProgressView()
                    .frame(width: 100, height: 100)
            }
            
            VStack(spacing: 4) {
                Text(name.capitalized)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("#\(String(format: "%03d", number))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 8) {
                ForEach(types, id: \.self) { type in
                    Text(type.capitalized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(pokemonTypeColor(type).opacity(0.2))
                        .foregroundColor(pokemonTypeColor(type))
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
    
    private func pokemonTypeColor(_ type: String) -> Color {
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