//
//  View+AnimationEffects.swift
//  FoundationLabsKit
//
//  Created by Rudrank Riyam on 7/1/25.
//

import SwiftUI

// MARK: - Animation Effects

/// Breathing animation effect
public struct BreathingEffect: ViewModifier {
    @State private var isAnimating = false
    var duration: Double = 3.0
    
    public func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? 1.05 : 1.0)
            .opacity(isAnimating ? 0.8 : 1.0)
            .animation(
                .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

/// Pulse effect for highlighting elements
public struct PulseEffect: ViewModifier {
    @State private var isPulsing = false
    var color: Color = .red
    
    public func body(content: Content) -> some View {
        content
            .background(
                Circle()
                    .fill(color.opacity(0.3))
                    .scaleEffect(isPulsing ? 1.5 : 1.0)
                    .opacity(isPulsing ? 0 : 1)
                    .animation(
                        .easeOut(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: isPulsing
                    )
            )
            .onAppear {
                isPulsing = true
            }
    }
}

/// Shimmer effect for loading states
public struct ShimmerEffect: ViewModifier {
    @State private var isAnimating = false
    var gradientColors: [Color] = [
        Color.gray.opacity(0.3),
        Color.gray.opacity(0.1),
        Color.gray.opacity(0.3)
    ]
    
    public func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: isAnimating ? geometry.size.width : -geometry.size.width)
                    .animation(
                        .linear(duration: 2)
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
                }
                .clipped()
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - View Animation Extensions
public extension View {
    /// Apply breathing animation
    func breathing(duration: Double = 3.0) -> some View {
        modifier(BreathingEffect(duration: duration))
    }
    
    /// Apply pulse effect
    func pulse(color: Color = .red) -> some View {
        modifier(PulseEffect(color: color))
    }
    
    /// Apply shimmer loading effect
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}