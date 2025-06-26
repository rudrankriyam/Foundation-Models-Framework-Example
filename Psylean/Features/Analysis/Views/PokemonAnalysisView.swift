//
//  PokemonAnalysisView.swift
//  Psylean
//
//  Created by Rudrank Riyam on 26/06/25.
//

import SwiftUI
import FoundationModels

struct PokemonAnalysisView: View {
    @State private var analyzer = PokemonAnalyzer()
    @State private var pokemonIdentifier = ""
    @State private var hasStartedAnalysis = false
    @Namespace private var glassNamespace
    
    init(pokemonIdentifier: String = "") {
        self._pokemonIdentifier = State(initialValue: pokemonIdentifier)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Pokemon Selector
                if !hasStartedAnalysis {
                    PokemonSelectorView(
                        pokemonIdentifier: $pokemonIdentifier,
                        showingPicker: .constant(false)
                    )
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Analysis Content
                if let analysis = analyzer.analysis {
                    StreamingPokemonView(analysis: analysis)
                } else if analyzer.isAnalyzing {
                    LoadingView(message: "Analyzing \(pokemonIdentifier.capitalized)...")
                } else if let error = analyzer.error {
                    ErrorView(error: error) {
                        Task {
                            await retryAnalysis()
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Psylean")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            if hasStartedAnalysis {
                ToolbarItem(placement: .primaryAction) {
                    if analyzer.isAnalyzing {
                        Button {
                            analyzer.stopAnalysis()
                        } label: {
                            Label("Stop", systemImage: "stop.circle.fill")
                                .foregroundStyle(.red)
                        }
                    } else {
                        Button("New Analysis") {
                            resetAnalysis()
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !hasStartedAnalysis && !analyzer.isAnalyzing && !pokemonIdentifier.isEmpty {
                AnalyzeButton {
                    await startAnalysis()
                }
                .padding(.bottom)
            }
        }
        .task {
            analyzer.prewarm()
        }
    }
    
    private func startAnalysis() async {
        guard !pokemonIdentifier.isEmpty else { return }
        
        hasStartedAnalysis = true
        analyzer.reset()
        
        do {
            try await analyzer.analyzePokemon(pokemonIdentifier)
        } catch {
            // Error is handled by the analyzer
        }
    }
    
    private func retryAnalysis() async {
        analyzer.reset()
        await startAnalysis()
    }
    
    private func resetAnalysis() {
        hasStartedAnalysis = false
        analyzer.reset()
        pokemonIdentifier = ""
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PokemonAnalysisView(pokemonIdentifier: "pikachu")
    }
}