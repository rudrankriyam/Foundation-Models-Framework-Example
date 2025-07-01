//
//  HealthEffects.swift
//  Body Buddy
//
//  Created by Rudrank Riyam on 6/23/25.
//

import SwiftUI

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
