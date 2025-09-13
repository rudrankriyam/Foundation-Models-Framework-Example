//
//  GenericCardView.swift
//  FoundationLab
//
//  Restored to satisfy usages in Examples and Tools views
//

import SwiftUI
import LiquidGlasKit

/// Generic card view used across example and tool lists
struct GenericCardView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer(minLength: 0)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
#if os(iOS) || os(macOS)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
#endif
    }
}

