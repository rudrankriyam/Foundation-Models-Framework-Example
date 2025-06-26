//
//  BattleAnalysisCard.swift
//  Psylean
//
//  Created by Rudrank Riyam on 26/06/25.
//

import SwiftUI
import FoundationModels

struct BattleAnalysisCard: View {
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