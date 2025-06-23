//
//  HealthEffects.swift
//  Body Buddy
//
//  Created by Rudrank Riyam on 6/23/25.
//

import SwiftUI

/// Breathing animation for health metrics
struct BreathingEffect: ViewModifier {
    @State private var isAnimating = false
    var duration: Double = 3.0
    
    func body(content: Content) -> some View {
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

/// Pulse effect for heart rate and similar metrics
struct PulseEffect: ViewModifier {
    @State private var isPulsing = false
    var color: Color = .heartColor
    
    func body(content: Content) -> some View {
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
struct ShimmerEffect: ViewModifier {
    @State private var isAnimating = false
    var gradientColors: [Color] = [
        Color.gray.opacity(0.3),
        Color.gray.opacity(0.1),
        Color.gray.opacity(0.3)
    ]
    
    func body(content: Content) -> some View {
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

/// Success celebration effect
struct CelebrationEffect: ViewModifier {
    @State private var isAnimating = false
    @State private var particles: [Particle] = []
    
    struct Particle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var velocity: CGVector
        var color: Color
        var size: CGFloat
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    ForEach(particles) { particle in
                        Circle()
                            .fill(particle.color)
                            .frame(width: particle.size, height: particle.size)
                            .position(particle.position)
                    }
                }
            )
            .onAppear {
                createParticles()
            }
    }
    
    private func createParticles() {
        for _ in 0..<20 {
            let particle = Particle(
                position: CGPoint(x: 150, y: 150),
                velocity: CGVector(
                    dx: Double.random(in: -100...100),
                    dy: Double.random(in: -200...(-50))
                ),
                color: [.healthPrimary, .healthSecondary, .healthAccent].randomElement()!,
                size: CGFloat.random(in: 4...8)
            )
            particles.append(particle)
        }
        
        withAnimation(.easeOut(duration: 2)) {
            for i in particles.indices {
                particles[i].position.x += particles[i].velocity.dx
                particles[i].position.y += particles[i].velocity.dy
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            particles.removeAll()
        }
    }
}

// MARK: - View Extensions
extension View {
    func breathing(duration: Double = 3.0) -> some View {
        modifier(BreathingEffect(duration: duration))
    }
    
    func pulse(color: Color = .heartColor) -> some View {
        modifier(PulseEffect(color: color))
    }
    
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
    
    func celebration() -> some View {
        modifier(CelebrationEffect())
    }
    
    /// Apply a gentle shadow for depth
    func healthShadow(radius: CGFloat = 8, opacity: Double = 0.1) -> some View {
        self.shadow(
            color: Color.black.opacity(opacity),
            radius: radius,
            x: 0,
            y: 4
        )
    }
    
    /// Apply a glow effect
    func healthGlow(color: Color, radius: CGFloat = 10) -> some View {
        self.shadow(color: color.opacity(0.6), radius: radius)
            .shadow(color: color.opacity(0.3), radius: radius * 2)
    }
}