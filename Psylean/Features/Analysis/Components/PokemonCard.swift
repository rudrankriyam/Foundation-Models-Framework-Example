//
//  PokemonCard.swift
//  Psylean
//
//  Created by Rudrank Riyam on 26/06/25.
//

import SwiftUI
import FoundationModels

struct PokemonCard: View {
    let name: String?
    let number: Int?
    let types: [PokemonType.PartiallyGenerated]?
    let description: String?
    
    var body: some View {
        VStack(spacing: 16) {
            // Image
            if let number = number {
                AsyncImage(url: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/\(number).png")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                } placeholder: {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                }
            }
            
            // Name & Number
            if let name = name {
                HStack {
                    Text(name.capitalized)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if let number = number {
                        Text("#\(String(format: "%03d", number))")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Types
            if let types = types, !types.isEmpty {
                HStack(spacing: 8) {
                    ForEach(Array(types.enumerated()), id: \.offset) { _, type in
                        if let typeName = type.name {
                            TypeBadge(type: typeName)
                        }
                    }
                }
            }
            
            // Description
            if let description = description {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}