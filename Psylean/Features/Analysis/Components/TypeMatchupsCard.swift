//
//  TypeMatchupsCard.swift
//  Psylean
//
//  Created by Rudrank Riyam on 26/06/25.
//

import SwiftUI
import FoundationModels

struct TypeMatchupsCard: View {
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
