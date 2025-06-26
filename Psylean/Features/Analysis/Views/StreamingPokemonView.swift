//
//  StreamingPokemonView.swift
//  Psylean
//
//  Created by Rudrank Riyam on 26/06/25.
//

import SwiftUI
import FoundationModels

struct StreamingPokemonView: View {
    let analysis: PokemonAnalysis.PartiallyGenerated
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            if let title = analysis.title {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            
            // Pokemon Card
            if let name = analysis.pokemonName {
                #if os(iOS) || os(macOS)
                GlassEffectContainer(spacing: 16) {
                    PokemonCard(
                        name: name,
                        number: analysis.pokedexNumber,
                        types: analysis.types,
                        description: analysis.poeticDescription
                    )
                }
                #else
                PokemonCard(
                    name: name,
                    number: analysis.pokedexNumber,
                    types: analysis.types,
                    description: analysis.poeticDescription
                )
                #endif
            }
            
            // Battle Analysis
            if analysis.battleRole != nil || analysis.statAnalysis != nil {
                #if os(iOS) || os(macOS)
                GlassEffectContainer(spacing: 12) {
                    BattleAnalysisCard(
                        role: analysis.battleRole,
                        statAnalysis: analysis.statAnalysis
                    )
                }
                #else
                BattleAnalysisCard(
                    role: analysis.battleRole,
                    statAnalysis: analysis.statAnalysis
                )
                #endif
            }
            
            // Abilities
            if let abilities = analysis.abilities, !abilities.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Abilities", systemImage: "star.fill")
                        .font(.headline)
                    
                    ForEach(Array(abilities.enumerated()), id: \.offset) { _, ability in
                        AbilityRow(ability: ability)
                    }
                }
            }
            
            // Type Matchups
            if let strengths = analysis.strengths, let weaknesses = analysis.weaknesses,
               !strengths.isEmpty || !weaknesses.isEmpty {
                #if os(iOS) || os(macOS)
                GlassEffectContainer(spacing: 16) {
                    TypeMatchupsCard(strengths: strengths, weaknesses: weaknesses)
                }
                #else
                TypeMatchupsCard(strengths: strengths, weaknesses: weaknesses)
                #endif
            }
            
            // Moves
            if let moves = analysis.recommendedMoves, !moves.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Recommended Moves", systemImage: "bolt.horizontal.fill")
                        .font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(moves, id: \.self) { move in
                            Text(move)
                                .font(.subheadline)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .frame(maxWidth: .infinity)
                                #if os(iOS) || os(macOS)
                                .glassEffect(.regular, in: .rect(cornerRadius: 8))
                                #endif
                        }
                    }
                }
            }
            
            // Evolution Chain
            if let evolutions = analysis.evolutionChain, !evolutions.isEmpty {
                EvolutionChainView(evolutions: evolutions)
            }
            
            // Fun Facts
            if let facts = analysis.funFacts, !facts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Fun Facts", systemImage: "lightbulb.fill")
                        .font(.headline)
                    
                    ForEach(Array(facts.enumerated()), id: \.offset) { _, fact in
                        Text("• \(fact)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Quote
            if let quote = analysis.legendaryQuote {
                Text("\"\(quote)\"")
                    .font(.callout)
                    .italic()
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.secondary)
                    .padding()
                    #if os(iOS) || os(macOS)
                    .glassEffect(.regular.tint(.orange.opacity(0.2)), in: .rect(cornerRadius: 12))
                    #endif
            }
        }
    }
}

// MARK: - Glass Effect Container

#if os(iOS) || os(macOS)
struct GlassEffectContainer<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }
}
#endif
