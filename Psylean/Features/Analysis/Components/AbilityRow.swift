//
//  AbilityRow.swift
//  Psylean
//
//  Created by Rudrank Riyam on 26/06/25.
//

import SwiftUI
import FoundationModels

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