//
//  ExampleButton.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/9/25.
//

import FoundationModels
import SwiftUI

/// Reusable button component for example actions with Liquid Glass effects
struct ExampleButton: View {
    let exampleType: ExampleType
    let action: () async -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button {
            Task {
                await action()
            }
        } label: {
            GenericCardView(
                icon: exampleType.icon,
                title: exampleType.title,
                subtitle: exampleType.subtitle
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
        } onPressingChanged: { pressing in
            if !pressing {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }
    }
}


/// Generic card view that can be used across all example types
struct GenericCardView: View {
    let icon: String
    let title: String
    let subtitle: String
    @Environment(\.colorScheme) var scheme
    
    var fill: Color {
        switch scheme {
        case .dark:
            return Color.clear.opacity(0.1)
        case .light:
            return Color.secondary.opacity(0.1)
        @unknown default:
            return Color.clear
        }
    }
    
    
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.medium)
        .background {
            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                .fill(fill)
                .glassEffect(.clear.interactive(), in: .rect(cornerRadius: CornerRadius.medium))
        }
    }
}
