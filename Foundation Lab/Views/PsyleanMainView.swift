//
//  PsyleanMainView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 7/1/25.
//

import SwiftUI

struct PsyleanMainView: View {
    @State private var selectedPokemon = "pikachu"
    
    var body: some View {
        // NOTE: To complete the integration:
        // 1. Add Psylean files to Foundation Lab target in Xcode
        // 2. Import Psylean module: `import Psylean`
        // 3. Replace this view with: PokemonAnalysisView()
        
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles.rectangle.stack.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.purple)
                        
                        Text("Psylean")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Beautiful Pokémon Analysis")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Mock Pokemon Card
                    VStack(spacing: 16) {
                        // Pokemon Image Placeholder
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(
                                colors: [.yellow.opacity(0.3), .orange.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(height: 200)
                            .overlay(
                                VStack {
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 60))
                                        .foregroundStyle(.yellow)
                                    Text("Pikachu")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                }
                            )
                        
                        // Type Badges
                        HStack {
                            TypeBadgePlaceholder(type: "Electric", color: .yellow)
                        }
                        
                        // Stats Preview
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Base Stats")
                                .font(.headline)
                            
                            StatRowPlaceholder(stat: "HP", value: 35, maxValue: 100, color: .green)
                            StatRowPlaceholder(stat: "Attack", value: 55, maxValue: 100, color: .red)
                            StatRowPlaceholder(stat: "Defense", value: 40, maxValue: 100, color: .blue)
                            StatRowPlaceholder(stat: "Speed", value: 90, maxValue: 100, color: .purple)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Integration Note
                    VStack(spacing: 12) {
                        Label("Integration Required", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .foregroundStyle(.orange)
                        
                        Text("To see the full Psylean Pokémon analysis with AI-powered insights, the Psylean files need to be added to the Foundation Lab target in Xcode.")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .padding()
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Psylean")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}

struct TypeBadgePlaceholder: View {
    let type: String
    let color: Color
    
    var body: some View {
        Text(type)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color)
            .cornerRadius(12)
    }
}

struct StatRowPlaceholder: View {
    let stat: String
    let value: Int
    let maxValue: Int
    let color: Color
    
    var body: some View {
        HStack {
            Text(stat)
                .font(.caption)
                .frame(width: 60, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(value) / CGFloat(maxValue), height: 8)
                }
            }
            .frame(height: 8)
            
            Text("\(value)")
                .font(.caption.monospacedDigit())
                .frame(width: 30, alignment: .trailing)
        }
    }
}

#Preview {
    PsyleanMainView()
}