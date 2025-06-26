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
                        .background(Color.pokemonType(type).opacity(0.2))
                        .foregroundColor(Color.pokemonType(type))
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}