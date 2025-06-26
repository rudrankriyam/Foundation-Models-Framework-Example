//
//  EvolutionChainView.swift
//  Psylean
//
//  Created by Rudrank Riyam on 26/06/25.
//

import SwiftUI
import FoundationModels

struct EvolutionChainView: View {
    let evolutions: [Evolution.PartiallyGenerated]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Evolution Chain", systemImage: "arrow.right.circle.fill")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(evolutions.enumerated()), id: \.offset) { index, evolution in
                        if index > 0 {
                            Image(systemName: "arrow.right")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                        
                        EvolutionStage(evolution: evolution)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}

struct EvolutionStage: View {
    let evolution: Evolution.PartiallyGenerated
    
    var body: some View {
        VStack(spacing: 8) {
            if let name = evolution.pokemonName {
                Text(name.capitalized)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            if let method = evolution.evolutionMethod {
                Text(method)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if let requirement = evolution.evolutionRequirement {
                Text(requirement)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        #if os(iOS) || os(macOS)
        .glassEffect(.regular, in: .rect(cornerRadius: 12))
        #endif
    }
}