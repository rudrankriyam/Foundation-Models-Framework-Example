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
    
    var body: some View {
        VStack(spacing: 16) {
            // Pokemon Image with shadow
            AsyncImage(url: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/\(number).png")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .overlay(
                        ProgressView()
                            .tint(.gray)
                    )
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
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                #if os(macOS)
                .fill(Color(NSColor.windowBackgroundColor))
                #else
                .fill(Color(UIColor.systemBackground))
                #endif
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
        .padding(.horizontal, 4)
    }
}
