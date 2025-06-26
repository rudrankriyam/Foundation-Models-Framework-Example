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
            TextField("Enter Pokemon name or ID", text: $pokemonIdentifier)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
            
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