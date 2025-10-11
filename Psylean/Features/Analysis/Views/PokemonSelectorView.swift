//
//  PokemonSelectorView.swift
//  Psylean
//
//  Created by Rudrank Riyam on 26/06/25.
//

import SwiftUI

struct PokemonSelectorView: View {
    @Binding var pokemonIdentifier: String
    @Binding var showingPicker: Bool
    @State private var showExamples = true

    let popularPokemon = [
        ("pikachu", "25", "Electric"),
        ("charizard", "6", "Fire/Flying"),
        ("mewtwo", "150", "Psychic"),
        ("eevee", "133", "Normal"),
        ("lucario", "448", "Fighting/Steel"),
        ("garchomp", "445", "Dragon/Ground")
    ]

    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                TextField("Enter Pokemon name, ID, or description", text: $pokemonIdentifier)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif

                Text("Try: 'cute grass pokemon', 'fierce fire type', or 'pikachu'")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Toggle between examples and popular
            HStack {
                Button {
                    showExamples = true
                } label: {
                    Text("Example Searches")
                        .font(.subheadline)
                        .fontWeight(showExamples ? .medium : .regular)
                        .foregroundStyle(showExamples ? .primary : .secondary)
                }

                Spacer()

                Button {
                    showExamples = false
                } label: {
                    Text("Popular Pokemon")
                        .font(.subheadline)
                        .fontWeight(!showExamples ? .medium : .regular)
                        .foregroundStyle(!showExamples ? .primary : .secondary)
                }
            }
            .padding(.horizontal, 4)

            if showExamples {
                // Example Searches
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach([
                        "cute water pokemon",
                        "fierce dragon type",
                        "small electric pokemon",
                        "legendary psychic",
                        "fast flying type",
                        "strong fighting type"
                    ], id: \.self) { example in
                        Button {
                            pokemonIdentifier = example
                        } label: {
                            Text(example)
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 8)
                                .foregroundStyle(.primary)
                        }
                        #if os(iOS) || os(macOS)
                        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 8))
                        #endif
                    }
                }
            } else {
                // Popular Pokemon
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(popularPokemon, id: \.0) { pokemon in
                        Button {
                            pokemonIdentifier = pokemon.0
                        } label: {
                            VStack(spacing: 8) {
                                AsyncImage(url: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/\(pokemon.1).png")) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(width: 80, height: 80)

                                Text(pokemon.0.capitalized)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundStyle(.primary)
                        }
                        #if os(iOS) || os(macOS)
                        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
                        #endif
                    }
                }
            }
        }
    }
}
