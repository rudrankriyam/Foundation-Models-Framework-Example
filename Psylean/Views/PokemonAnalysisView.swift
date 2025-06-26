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
    
    init(pokemonIdentifier: String = "") {
        self._analyzer = State(initialValue: PokemonAnalyzer(pokemonIdentifier: pokemonIdentifier))
        self._pokemonIdentifier = State(initialValue: pokemonIdentifier)
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
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
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.red)
                            Text("Error: \(error.localizedDescription)")
                                .foregroundStyle(.white)
                            Button("Retry") {
                                Task {
                                    await retryAnalysis()
                                }
                            }
                        }
                        .padding()
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Psylean")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            if hasStartedAnalysis && !analyzer.isAnalyzing {
                ToolbarItem(placement: .primaryAction) {
                    Button("New Pokemon") {
                        resetAnalysis()
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !hasStartedAnalysis && !analyzer.isAnalyzing {
                CatchPokemonButton {
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
    
    private var backgroundColors: [Color] {
        if let analysis = analyzer.analysis,
           let types = analysis.types,
           !types.isEmpty {
            return types.prefix(2).map { typeColor(for: $0.name ?? "normal") }
        }
        return [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]
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
    
    private func typeColor(for type: String) -> Color {
        switch type.lowercased() {
        case "fire": return .red
        case "water": return .blue
        case "grass": return .green
        case "electric": return .yellow
        case "psychic": return .purple
        case "ice": return .cyan
        case "dragon": return .indigo
        case "dark": return .black.opacity(0.8)
        case "fairy": return .pink
        case "fighting": return .orange
        case "poison": return .purple.opacity(0.7)
        case "ground": return .brown
        case "flying": return .mint
        case "bug": return .green.opacity(0.7)
        case "rock": return .gray
        case "ghost": return .purple.opacity(0.5)
        case "steel": return .gray.opacity(0.8)
        default: return .gray.opacity(0.5)
        }
    }
}

// MARK: - Supporting Views

struct PokemonSelectorView: View {
    @Binding var pokemonIdentifier: String
    @Binding var showingPicker: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(.white)
                .symbolEffect(.pulse)
            
            Text("Choose Your Pokemon")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            VStack(spacing: 16) {
                TextField("Enter Pokemon name or ID", text: $pokemonIdentifier)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
                
                Text("or")
                    .foregroundStyle(.white.opacity(0.8))
                
                Button {
                    showingPicker = true
                } label: {
                    Label("Browse Pokemon", systemImage: "square.grid.3x3")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.white.opacity(0.2))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding()
    }
}

struct StreamingPokemonView: View {
    let analysis: PokemonAnalysis.PartiallyGenerated
    @State private var appearAnimation = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Title Section
            if let title = analysis.title {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .shadow(radius: 4)
                    .transition(.scale.combined(with: .opacity))
                    .scaleEffect(appearAnimation ? 1 : 0.8)
                    .opacity(appearAnimation ? 1 : 0)
            }
            
            // Pokemon Card
            if let name = analysis.pokemonName {
                PokemonCardView(
                    name: name,
                    number: analysis.pokedexNumber,
                    types: analysis.types,
                    description: analysis.poeticDescription
                )
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .opacity
                ))
            }
            
            // Battle Role & Stats
            if analysis.battleRole != nil || analysis.statAnalysis != nil {
                BattleInfoSection(
                    role: analysis.battleRole,
                    statAnalysis: analysis.statAnalysis
                )
            }
            
            // Abilities
            if let abilities = analysis.abilities, !abilities.isEmpty {
                AbilitiesSection(abilities: abilities)
            }
            
            // Type Matchups
            if let strengths = analysis.strengths, let weaknesses = analysis.weaknesses,
               !strengths.isEmpty || !weaknesses.isEmpty {
                TypeMatchupSection(strengths: strengths, weaknesses: weaknesses)
            }
            
            // Recommended Moves
            if let moves = analysis.recommendedMoves, !moves.isEmpty {
                MovesSection(moves: moves)
            }
            
            // Fun Facts & Quote
            if analysis.funFacts != nil || analysis.legendaryQuote != nil {
                FunFactsSection(facts: analysis.funFacts, quote: analysis.legendaryQuote)
            }
        }
        .animation(.smooth, value: analysis)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appearAnimation = true
            }
        }
    }
}

struct PokemonCardView: View {
    let name: String?
    let number: Int?
    let types: [PokemonType.PartiallyGenerated]?
    let description: String?
    
    @State private var isFlipped = false
    @State private var shimmerAnimation = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Pokemon Image Placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .frame(height: 200)
                
                if let number = number {
                    AsyncImage(url: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/\(number).png")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 180)
                    } placeholder: {
                        Image(systemName: "sparkles")
                            .font(.system(size: 80))
                            .foregroundStyle(.white.opacity(0.5))
                            .symbolEffect(.pulse)
                    }
                }
            }
            .rotation3DEffect(
                .degrees(isFlipped ? 180 : 0),
                axis: (x: 0, y: 1, z: 0)
            )
            .onTapGesture {
                withAnimation(.spring()) {
                    isFlipped.toggle()
                }
            }
            
            // Name & Number
            if let name = name {
                HStack {
                    Text(name.capitalized)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    if let number = number {
                        Text("#\(String(format: "%03d", number))")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
            }
            
            // Types
            if let types = types, !types.isEmpty {
                HStack(spacing: 12) {
                    ForEach(Array(types.enumerated()), id: \.offset) { _, type in
                        if let typeName = type.name {
                            TypeBadge(type: typeName, color: type.colorDescription ?? "gray")
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
            }
            
            // Poetic Description
            if let description = description {
                Text(description)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(shimmerAnimation ? 0.6 : 0.2), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            }
        }
        .padding()
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                shimmerAnimation = true
            }
        }
    }
}

struct TypeBadge: View {
    let type: String
    let color: String
    
    var body: some View {
        Text(type.capitalized)
            .font(.subheadline)
            .fontWeight(.semibold)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(typeBackgroundColor)
            .foregroundColor(.white)
            .clipShape(Capsule())
            .shadow(color: typeBackgroundColor.opacity(0.5), radius: 4)
    }
    
    private var typeBackgroundColor: Color {
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
        default: return .gray
        }
    }
}

struct BattleInfoSection: View {
    let role: BattleRole?
    let statAnalysis: StatAnalysis.PartiallyGenerated?
    
    var body: some View {
        VStack(spacing: 16) {
            if let role = role {
                Label(role.rawValue, systemImage: battleRoleIcon(for: role))
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
            }
            
            if let stats = statAnalysis {
                StatAnalysisCard(stats: stats)
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

struct StatAnalysisCard: View {
    let stats: StatAnalysis.PartiallyGenerated
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Stats Analysis", systemImage: "chart.bar.fill")
                .font(.headline)
                .foregroundStyle(.white)
            
            if let total = stats.totalStats {
                HStack {
                    Text("Total Base Stats:")
                    Spacer()
                    Text("\(total)")
                        .fontWeight(.bold)
                }
                .foregroundStyle(.white)
            }
            
            if let strongest = stats.strongestStat, let weakest = stats.weakestStat {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Strongest")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                        Text(strongest)
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Weakest")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                        Text(weakest)
                            .fontWeight(.semibold)
                            .foregroundStyle(.red)
                    }
                }
            }
            
            if let strategy = stats.battleStrategy {
                Text(strategy)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding()
                    .background(.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct AbilitiesSection: View {
    let abilities: [AbilityAnalysis.PartiallyGenerated]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Abilities", systemImage: "star.fill")
                .font(.headline)
                .foregroundStyle(.white)
            
            ForEach(Array(abilities.enumerated()), id: \.offset) { _, ability in
                AbilityCard(ability: ability)
                    .transition(.asymmetric(
                        insertion: .push(from: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct AbilityCard: View {
    let ability: AbilityAnalysis.PartiallyGenerated
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
        HStack {
                if let name = ability.name {
                    Text(name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
                
                if let isHidden = ability.isHidden, isHidden {
                    Text("Hidden")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.purple)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                
                Spacer()
                
                if let rating = ability.synergyRating {
                    HStack(spacing: 2) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < rating ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }
                }
            }
            
            if let use = ability.strategicUse {
                Text(use)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding()
        .background(.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct TypeMatchupSection: View {
    let strengths: [TypeMatchup.PartiallyGenerated]
    let weaknesses: [TypeMatchup.PartiallyGenerated]
    
    var body: some View {
        VStack(spacing: 16) {
            if !strengths.isEmpty {
                MatchupList(title: "Strong Against", icon: "checkmark.shield.fill", matchups: strengths, isStrength: true)
            }
            
            if !weaknesses.isEmpty {
                MatchupList(title: "Weak Against", icon: "exclamationmark.shield.fill", matchups: weaknesses, isStrength: false)
            }
        }
    }
}

struct MatchupList: View {
    let title: String
    let icon: String
    let matchups: [TypeMatchup.PartiallyGenerated]
    let isStrength: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.white)
            
            ForEach(Array(matchups.enumerated()), id: \.offset) { _, matchup in
                if let type = matchup.type, let effectiveness = matchup.effectiveness {
                    HStack {
                        TypeBadge(type: type, color: "")
                        
                        Spacer()
                        
                        Text("×\(String(format: "%.1f", effectiveness))")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(isStrength ? .green : .red)
                        
                        if let tip = matchup.tip {
                            Text(tip)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct MovesSection: View {
    let moves: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recommended Moves", systemImage: "bolt.horizontal.fill")
                .font(.headline)
                .foregroundStyle(.white)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(moves, id: \.self) { move in
                    Text(move)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.white.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .foregroundStyle(.white)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct FunFactsSection: View {
    let facts: [String]?
    let quote: String?
    
    var body: some View {
        VStack(spacing: 16) {
            if let facts = facts, !facts.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Fun Facts", systemImage: "lightbulb.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    ForEach(Array(facts.enumerated()), id: \.offset) { _, fact in
                        HStack(alignment: .top) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text(fact)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            if let quote = quote {
                Text("\"\(quote)\"")
                    .font(.title3)
                    .italic()
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.yellow.opacity(0.5), .orange.opacity(0.5)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                    )
            }
        }
    }
}

struct PokemonLoadingView: View {
    let pokemonName: String
    @State private var rotation = 0.0
    @State private var scale = 1.0
    
    var body: some View {
        VStack(spacing: 24) {
            // Pokeball animation
            Image(systemName: "circle.hexagongrid.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(rotation))
                .scaleEffect(scale)
                .onAppear {
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                    withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                        scale = 1.2
                    }
                }
            
            VStack(spacing: 8) {
                Text("Analyzing \(pokemonName.capitalized)...")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                
                Text("Gathering data from the Pokedex")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 100)
    }
}

struct CatchPokemonButton: View {
    let action: () async -> Void
    @State private var isAnimating = false
    @State private var bounceAnimation = false
    
    var body: some View {
        Button {
            Task {
                isAnimating = true
                await action()
                isAnimating = false
            }
        } label: {
            HStack {
                Image(systemName: "sparkles")
                    .symbolEffect(.bounce.up, value: bounceAnimation)
                
                Text("Analyze Pokemon")
                    .fontWeight(.semibold)
                
                Image(systemName: "sparkles")
                    .symbolEffect(.bounce.up, value: bounceAnimation)
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [.red, .white],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.black)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 4)
        }
        .disabled(isAnimating)
        .padding()
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Divider()
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
                bounceAnimation.toggle()
            }
        }
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
        ("gyarados", "130", "Water/Flying")
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
                            Text(pokemon.0.capitalized)
                                .font(.headline)
                            
                            Text("#\(pokemon.1)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Text(pokemon.2)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.accentColor.opacity(0.1))
                                .foregroundColor(.accentColor)
                                .clipShape(Capsule())
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

// MARK: - Preview

#Preview {
    NavigationStack {
        PokemonAnalysisView(pokemonIdentifier: "pikachu")
    }
}
