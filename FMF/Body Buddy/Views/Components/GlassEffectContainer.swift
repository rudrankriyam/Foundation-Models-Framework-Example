//
//  GlassEffectContainer.swift
//  Body Buddy
//
//  Created by Rudrank Riyam on 6/23/25.
//

import SwiftUI

/// A container view that provides consistent glass effect styling
struct GlassEffectContainer<Content: View>: View {
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    @ViewBuilder let content: () -> Content
    
    init(
        spacing: CGFloat = 8,
        alignment: HorizontalAlignment = .leading,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.spacing = spacing
        self.alignment = alignment
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            content()
        }
    }
}

/// Health-themed glass effect styles
extension View {
    func healthGlassEffect(
        _ style: HealthGlassStyle = .regular,
        in shape: some Shape = RoundedRectangle(cornerRadius: 16)
    ) -> some View {
        self.glassEffect(style.glassConfiguration, in: shape)
    }
}

enum HealthGlassStyle {
    case regular
    case metric(color: Color)
    case alert
    case celebration
    case subtle
    
    var glassConfiguration: Glass {
        switch self {
        case .regular:
            return .regular
        case .metric(let color):
            return .regular.tint(color.opacity(0.3))
        case .alert:
            return .regular.tint(.red.opacity(0.3))
        case .celebration:
            return .regular.tint(.green.opacity(0.3))
        case .subtle:
            return .regular.tint(.gray.opacity(0.2))
        }
    }
}

/// Reusable glass card component
struct GlassCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 16
    
    init(
        padding: CGFloat = 16,
        cornerRadius: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
    }
}

/// Animated glass button style
struct GlassButtonStyle: ButtonStyle {
    @State private var isPressed = false
    var cornerRadius: CGFloat = 12
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .glassEffect(
                configuration.isPressed
                    ? .regular.tint(.accentColor.opacity(0.3)).interactive()
                    : .regular.interactive(),
                in: .rect(cornerRadius: cornerRadius)
            )
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}