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
            
            // Example Searches
            VStack(alignment: .leading, spacing: 12) {
                Text("Example Searches")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach([
                            "cute water pokemon",
                            "fierce dragon type",
                            "small electric pokemon",
                            "legendary psychic",
                            "fast flying type"
                        ], id: \.self) { example in
                            Button {
                                pokemonIdentifier = example
                            } label: {
                                Text(example)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .foregroundStyle(.primary)
                            }
                            #if os(iOS) || os(macOS)
                            .glassEffect(.regular.interactive(), in: .capsule)
                            #endif
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Popular Pokemon")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
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
                                .frame(width: 60, height: 60)
                                
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