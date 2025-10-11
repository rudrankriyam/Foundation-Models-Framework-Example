//
//  TypeBadge.swift
//  Psylean
//
//  Created by Rudrank Riyam on 26/06/25.
//

import SwiftUI

struct TypeBadge: View {
    let type: String
    var small = false

    var body: some View {
        Text(type.capitalized)
            .font(small ? .caption : .subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, small ? 8 : 12)
            .padding(.vertical, small ? 4 : 6)
            .background(Color.pokemonType(type).opacity(0.2))
            .foregroundColor(Color.pokemonType(type))
            .clipShape(Capsule())
    }
}
