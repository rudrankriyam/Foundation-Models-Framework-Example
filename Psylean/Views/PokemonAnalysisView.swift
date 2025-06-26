//
//  PokemonAnalysisView.swift
//  Psylean
//
//  Created by Rudrank Riyam on 26/06/25.
//

import SwiftUI
import FoundationModels

struct PokemonAnalysisView: View {
    @State private var analyzer: PokemonAnalyzer
    @State private var pokemonIdentifier = ""
    @State private var hasStartedAnalysis = false
    @State private var showingPokemonPicker = false
    @Namespace private var glassNamespace
    
    init(pokemonIdentifier: String = "") {
        self._analyzer = State(initialValue: PokemonAnalyzer(pokemonIdentifier: pokemonIdentifier))
        self._pokemonIdentifier = State(initialValue: pokemonIdentifier)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Pokemon Selector
                if !hasStartedAnalysis {
                    PokemonSelectorView(
                        pokemonIdentifier: $pokemonIdentifier,
                        showingPicker: $showingPokemonPicker
                    )
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Analysis Content
                if let analysis = analyzer.analysis {
                    StreamingPokemonView(analysis: analysis)
                } else if analyzer.isAnalyzing {
                    PokemonLoadingView(pokemonName: pokemonIdentifier)
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
            if hasStartedAnalysis && !analyzer.isAnalyzing {
                ToolbarItem(placement: .primaryAction) {
                    Button("New Analysis") {
                        resetAnalysis()
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !hasStartedAnalysis && !analyzer.isAnalyzing && !pokemonIdentifier.isEmpty {
                AnalyzeButton {
                    await startAnalysis()
                }
            }
        }
        .sheet(isPresented: $showingPokemonPicker) {
            PokemonPickerView(selectedPokemon: $pokemonIdentifier)
        }
        .task {
            analyzer.prewarm()
        }
    }
    
    private func startAnalysis() async {
        guard !pokemonIdentifier.isEmpty else { return }
        
        hasStartedAnalysis = true
        analyzer = PokemonAnalyzer(pokemonIdentifier: pokemonIdentifier)
        
        do {
            try await analyzer.analyzePokemon()
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

// MARK: - Supporting Views

struct PokemonSelectorView: View {
    @Binding var pokemonIdentifier: String
    @Binding var showingPicker: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            TextField("Enter Pokemon name or ID", text: $pokemonIdentifier)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
            
            Button {
                showingPicker = true
            } label: {
                Label("Browse Popular Pokemon", systemImage: "square.grid.3x3")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundStyle(.primary)
            }
            #if os(iOS) || os(macOS)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
            #endif
        }
    }
}

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
                    .transition(.opacity)
            }
            
            // Pokemon Card
            if let name = analysis.pokemonName {
                #if os(iOS) || os(macOS)
                GlassEffectContainer(spacing: 16) {
                    PokemonCardContent(
                        name: name,
                        number: analysis.pokedexNumber,
                        types: analysis.types,
                        description: analysis.poeticDescription
                    )
                }
                #else
                PokemonCardContent(
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
                    BattleAnalysisContent(
                        role: analysis.battleRole,
                        statAnalysis: analysis.statAnalysis
                    )
                }
                #else
                BattleAnalysisContent(
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
                    TypeMatchupsContent(strengths: strengths, weaknesses: weaknesses)
                }
                #else
                TypeMatchupsContent(strengths: strengths, weaknesses: weaknesses)
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
                    .foregroundStyle(.secondary)
                    .padding()
                    #if os(iOS) || os(macOS)
                    .glassEffect(.regular.tint(.orange.opacity(0.2)), in: .rect(cornerRadius: 12))
                    #endif
            }
        }
        .animation(.smooth, value: analysis)
    }
}

struct PokemonCardContent: View {
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
                        .frame(height: 180)
                } placeholder: {
                    ProgressView()
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
            }
        }
    }
}

struct BattleAnalysisContent: View {
    let role: BattleRole?
    let statAnalysis: StatAnalysis.PartiallyGenerated?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let role = role {
                HStack {
                    Label(role.rawValue, systemImage: battleRoleIcon(for: role))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
            }
            
            if let stats = statAnalysis {
                if let total = stats.totalStats {
                    HStack {
                        Text("Total Base Stats")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(total)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
                
                if let strategy = stats.battleStrategy {
                    Text(strategy)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private func battleRoleIcon(for role: BattleRole) -> String {
        switch role {
        case .physicalAttacker: return "bolt.fill"
        case .specialAttacker: return "sparkles"
        case .tank: return "shield.fill"
        case .speedster: return "hare.fill"
        case .support: return "heart.fill"
        case .mixedAttacker: return "burst.fill"
        case .wall: return "lock.shield.fill"
        }
    }
}

struct TypeMatchupsContent: View {
    let strengths: [TypeMatchup.PartiallyGenerated]
    let weaknesses: [TypeMatchup.PartiallyGenerated]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !strengths.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Strong Against", systemImage: "checkmark.shield.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.green)
                    
                    ForEach(Array(strengths.enumerated()), id: \.offset) { _, matchup in
                        if let type = matchup.type {
                            HStack {
                                TypeBadge(type: type, small: true)
                                Spacer()
                                if let effectiveness = matchup.effectiveness {
                                    Text("×\(String(format: "%.1f", effectiveness))")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                    }
                }
            }
            
            if !weaknesses.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Weak Against", systemImage: "exclamationmark.shield.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.red)
                    
                    ForEach(Array(weaknesses.enumerated()), id: \.offset) { _, matchup in
                        if let type = matchup.type {
                            HStack {
                                TypeBadge(type: type, small: true)
                                Spacer()
                                if let effectiveness = matchup.effectiveness {
                                    Text("×\(String(format: "%.1f", effectiveness))")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct AbilityRow: View {
    let ability: AbilityAnalysis.PartiallyGenerated
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if let name = ability.name {
                        Text(name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    if let isHidden = ability.isHidden, isHidden {
                        Text("Hidden")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.purple.opacity(0.2))
                            .foregroundColor(.purple)
                            .clipShape(Capsule())
                    }
                }
                
                if let use = ability.strategicUse {
                    Text(use)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if let rating = ability.synergyRating {
                Text("\(rating)/10")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        #if os(iOS) || os(macOS)
        .glassEffect(.regular, in: .rect(cornerRadius: 12))
        #endif
    }
}

struct TypeBadge: View {
    let type: String
    var small = false
    
    var body: some View {
        Text(type.capitalized)
            .font(small ? .caption : .subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, small ? 8 : 12)
            .padding(.vertical, small ? 4 : 6)
            .background(typeColor.opacity(0.2))
            .foregroundColor(typeColor)
            .clipShape(Capsule())
    }
    
    private var typeColor: Color {
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

struct PokemonLoadingView: View {
    let pokemonName: String
    @State private var animateDots = false
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Analyzing \(pokemonName.capitalized)...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding(40)
        #if os(iOS) || os(macOS)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
        #endif
    }
}

struct ErrorView: View {
    let error: Error
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)
            
            Text("Failed to fetch Pokemon data")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                retry()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        #if os(iOS) || os(macOS)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
        #endif
    }
}

struct AnalyzeButton: View {
    let action: () async -> Void
    @State private var isLoading = false
    
    var body: some View {
        Button {
            Task {
                isLoading = true
                await action()
                isLoading = false
            }
        } label: {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "sparkles")
                }
                Text("Analyze Pokemon")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundStyle(.white)
            .background(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isLoading)
        .padding()
        .background(.ultraThinMaterial)
    }
}

struct PokemonPickerView: View {
    @Binding var selectedPokemon: String
    @Environment(\.dismiss) private var dismiss
    
    let popularPokemon = [
        ("pikachu", "25", "Electric"),
        ("charizard", "6", "Fire/Flying"),
        ("mewtwo", "150", "Psychic"),
        ("eevee", "133", "Normal"),
        ("lucario", "448", "Fighting/Steel"),
        ("garchomp", "445", "Dragon/Ground"),
        ("gengar", "94", "Ghost/Poison"),
        ("dragonite", "149", "Dragon/Flying"),
        ("snorlax", "143", "Normal"),
        ("gyarados", "130", "Water/Flying"),
        ("blaziken", "257", "Fire/Fighting"),
        ("umbreon", "197", "Dark"),
        ("sylveon", "700", "Fairy"),
        ("greninja", "658", "Water/Dark"),
        ("zoroark", "571", "Dark")
    ]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(popularPokemon, id: \.0) { pokemon in
                    Button {
                        selectedPokemon = pokemon.0
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(pokemon.0.capitalized)
                                    .font(.headline)
                                Text("#\(pokemon.1)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(pokemon.2)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Popular Pokemon")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Glass Effect Container


// MARK: - Preview

#Preview {
    NavigationStack {
        PokemonAnalysisView(pokemonIdentifier: "pikachu")
    }
}
