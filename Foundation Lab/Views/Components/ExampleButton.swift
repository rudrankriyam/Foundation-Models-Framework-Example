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
            ExampleCardView(type: exampleType)
                .pressed(isPressed)
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

struct ExampleCardView: View {
    let type: ExampleType

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Image(systemName: type.icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(type.title)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text(type.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        #if os(iOS)
        .background(Color(UIColor.quaternarySystemFill))
        #else
        .background(Color(NSColor.quaternaryLabelColor).opacity(0.05))
        #endif
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.primary.opacity(0.05), lineWidth: 1)
        )
    }


    func pressed(_ isPressed: Bool) -> some View {
        self
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
    }
}
