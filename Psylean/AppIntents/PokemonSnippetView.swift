//
//  PokemonSnippetView.swift
//  Psylean
//
//  Created by Rudrank Riyam on 26/06/25.
//

import SwiftUI

struct PokemonSnippetView: View {
    let name: String
    let number: Int
    let types: [String]
    let imageData: Data?
    
    private var pokemonGradient: LinearGradient {
        let colors = types.isEmpty ? [Color.gray] : types.map { Color.pokemonType($0) }
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var pokemonIconName: String {
        guard let primaryType = types.first?.lowercased() else { return "sparkles" }
        
        switch primaryType {
        case "fire": return "flame.fill"
        case "water": return "drop.fill"
        case "grass": return "leaf.fill"
        case "electric": return "bolt.fill"
        case "psychic": return "brain"
        case "ice": return "snowflake"
        case "dragon": return "sparkles"
        case "dark": return "moon.fill"
        case "fairy": return "star.fill"
        case "fighting": return "figure.boxing"
        case "poison": return "smoke.fill"
        case "ground": return "mountain.2.fill"
        case "flying": return "wind"
        case "bug": return "ant.fill"
        case "rock": return "cube.fill"
        case "ghost": return "eye.slash.fill"
        case "steel": return "shield.fill"
        case "normal": return "circle.fill"
        default: return "sparkles"
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Pokemon Image - Using synchronously loaded data
            Group {
                if let imageData = imageData {
                    // Show the actual Pokemon image
                    #if os(macOS)
                    if let nsImage = NSImage(data: imageData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .background(
                                Circle()
                                    .fill(pokemonGradient.opacity(0.1))
                            )
                    }
                    #else
                    if let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .background(
                                Circle()
                                    .fill(pokemonGradient.opacity(0.1))
                            )
                    }
                    #endif
                } else {
                    // Fallback to type-themed icon
                    ZStack {
                        Circle()
                            .fill(pokemonGradient.opacity(0.2))
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .strokeBorder(pokemonGradient, lineWidth: 3)
                            .frame(width: 120, height: 120)
                        
                        // Pokemon-themed icon based on primary type
                        Image(systemName: pokemonIconName)
                            .font(.system(size: 50, weight: .medium))
                            .foregroundStyle(pokemonGradient)
                    }
                }
            }

            // Name and Number
            VStack(spacing: 6) {
                Text(name.capitalized)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("#\(String(format: "%03d", number))")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            
            // Type badges
            HStack(spacing: 10) {
                ForEach(types, id: \.self) { type in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.pokemonType(type))
                            .frame(width: 8, height: 8)
                        
                        Text(type.capitalized)
                            .font(.footnote)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.pokemonType(type).opacity(0.15))
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.pokemonType(type).opacity(0.3), lineWidth: 1)
                            )
                    )
                    .foregroundColor(Color.pokemonType(type))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
