//
//  GlassCardModifier.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 8/17/25.
//

import SwiftUI

public struct GlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) var scheme
    public let radius: CGFloat
    
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
    
    public init(radius: CGFloat = 16) {
        self.radius = radius
    }
    
    public func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(fill)
                    .glassEffect(.clear.interactive(), in: .rect(cornerRadius: radius))
            }
    }
}

public extension View {
    func glassCard(radius: CGFloat = 16) -> some View {
        modifier(GlassCardModifier(radius: radius))
    }
}
