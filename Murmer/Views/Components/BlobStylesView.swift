//
//  BlobStylesView.swift
//  Murmer
//
//  Created by Rudrank Riyam on 6/26/25.
//

import SwiftUI

struct BlobStylesView: View {
    @StateObject private var audioManager = AudioManager()
    @State private var selectedStyle: BlobStyle = .organic
    
    private var backgroundColor: Color {
        #if os(iOS)
        Color(uiColor: .systemBackground)
        #else
        Color(nsColor: .windowBackgroundColor)
        #endif
    }

    enum BlobStyle: String, CaseIterable {
        case organic = "Organic"
        case liquid = "Liquid"
        case geometric = "Geometric"
        case particles = "Particles"

        var description: String {
            switch self {
            case .organic:
                return "Smooth, natural flowing movement"
            case .liquid:
                return "Fluid, water-like behavior"
            case .geometric:
                return "Sharp, angular transformations"
            case .particles:
                return "Particle system with audio reaction"
            }
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            // Style picker
            Picker("Blob Style", selection: $selectedStyle) {
                ForEach(BlobStyle.allCases, id: \.self) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // Selected blob view
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                backgroundColor,
                                Color.gray.opacity(0.07)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)

                // Selected blob
                Group {
                    switch selectedStyle {
                    case .organic:
                        AudioReactiveBlobView(audioManager: audioManager)
                    case .liquid:
                        LiquidBlobView(audioManager: audioManager)
                    case .geometric:
                        GeometricBlobView(audioManager: audioManager)
                    case .particles:
                        ParticleBlobView(audioManager: audioManager)
                    }
                }
                .frame(width: 250, height: 250)
            }
            .frame(height: 350)
            .padding(.horizontal)

            // Description
            Text(selectedStyle.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Audio level indicator
            VStack(spacing: 10) {
                Text("Audio Level")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ProgressView(value: audioManager.currentAmplitude)
                    .progressViewStyle(AudioLevelProgressStyle())
                    .frame(height: 20)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.vertical)
        .onAppear {
            audioManager.startAudioSession()
        }
        .onDisappear {
            audioManager.stopAudioSession()
        }
    }
}

// Liquid blob variant
struct LiquidBlobView: View {
    @ObservedObject var audioManager: AudioManager
    @State private var phase: Double = 0

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let baseRadius = min(size.width, size.height) / 3

            // Create liquid effect with multiple layers
            for i in 0..<5 {
                let layerPhase = phase + Double(i) * 0.4
                let radius = baseRadius * (1 - CGFloat(i) * 0.1)

                var path = Path()
                let points = 12

                for j in 0..<points {
                    let angle = (Double(j) / Double(points)) * 2 * .pi
                    let waveOffset = sin(angle * 3 + layerPhase) * 20 * audioManager.currentAmplitude
                    let r = radius + waveOffset

                    let x = center.x + cos(angle) * r
                    let y = center.y + sin(angle) * r

                    if j == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }

                path.closeSubpath()

                let gradient = Gradient(colors: [
                    Color.blue.opacity(0.6),
                    Color.purple.opacity(0.4)
                ])

                context.fill(
                    path,
                    with: .linearGradient(
                        gradient,
                        startPoint: .zero,
                        endPoint: CGPoint(x: size.width, y: size.height)
                    )
                )

                // Apply blur for liquid effect
                context.addFilter(.blur(radius: CGFloat(i) * 2))
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

// Geometric blob variant
struct GeometricBlobView: View {
    @ObservedObject var audioManager: AudioManager
    @State private var rotation: Double = 0
    @State private var scale: Double = 1

    var body: some View {
        ZStack {
            ForEach(0..<3) { i in
                PolygonShape(
                    sides: 6 - i,
                    audioLevel: audioManager.currentAmplitude
                )
                .fill(
                    LinearGradient(
                        colors: [
                            Color.cyan.opacity(0.6),
                            Color.mint.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .rotationEffect(.degrees(rotation + Double(i * 30)))
                .scaleEffect(scale - Double(Double(i) * 0.2))
                .blur(radius: CGFloat(i) * 1.5)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                rotation = 360
            }

            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                scale = 1.2
            }
        }
    }
}

struct PolygonShape: Shape {
    let sides: Int
    var audioLevel: Double

    nonisolated var animatableData: Double {
        get { audioLevel }
        set { audioLevel = newValue }
    }

    nonisolated func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 * (0.8 + CGFloat(audioLevel) * 0.4)
        let angleStep = (2 * .pi) / Double(sides)

        var path = Path()

        for i in 0..<sides {
            let angle = Double(i) * angleStep - .pi / 2
            let x = center.x + cos(angle) * radius
            let y = center.y + sin(angle) * radius

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        path.closeSubpath()
        return path
    }
}

// Particle blob variant
struct ParticleBlobView: View {
    @ObservedObject var audioManager: AudioManager
    @State private var particles: [Particle] = []
    @State private var time: Double = 0

    struct Particle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var velocity: CGVector
        var size: CGFloat
        var opacity: Double
        var hue: Double
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let currentTime = timeline.date.timeIntervalSinceReferenceDate

                // Update and draw particles
                for particle in particles {
                    let age = CGFloat(currentTime - time)
                    let audioBoost = CGFloat(audioManager.currentAmplitude * 2)

                    // Calculate position with audio influence
                    let x = particle.position.x + particle.velocity.dx * age * (1 + audioBoost)
                    let y = particle.position.y + particle.velocity.dy * age * (1 + audioBoost)

                    // Calculate distance from center
                    let distance = sqrt(pow(x - center.x, 2) + pow(y - center.y, 2))
                    let maxDistance = min(size.width, size.height) / 2

                    // Fade out based on distance
                    let opacity = particle.opacity * (1 - Double(distance / maxDistance))

                    // Draw particle
                    context.fill(
                        Circle().path(in: CGRect(
                            x: x - particle.size / 2,
                            y: y - particle.size / 2,
                            width: particle.size,
                            height: particle.size
                        )),
                        with: .color(
                            Color(
                                hue: particle.hue,
                                saturation: 0.8,
                                brightness: 0.9,
                                opacity: opacity
                            )
                        )
                    )
                }
            }
            .blur(radius: 2)
            .onChange(of: timeline.date) { _, _ in
                updateParticles()
            }
        }
        .onAppear {
            initializeParticles()
        }
    }

    private func initializeParticles() {
        particles = (0..<100).map { i in
            let angle = Double(i) / 100 * 2 * .pi
            let radius = Double.random(in: 50...100)

            return Particle(
                position: CGPoint(x: 125, y: 125),
                velocity: CGVector(
                    dx: cos(angle) * radius,
                    dy: sin(angle) * radius
                ),
                size: CGFloat.random(in: 3...8),
                opacity: Double.random(in: 0.5...1.0),
                hue: Double(i) / 100
            )
        }
        time = Date().timeIntervalSinceReferenceDate
    }

    private func updateParticles() {
        // Recreate particles when they fade out
        if particles.first?.opacity ?? 1 < 0.1 {
            initializeParticles()
        }
    }
}

// Custom progress view style
struct AudioLevelProgressStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.15))

                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [.green, .yellow, .orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * (configuration.fractionCompleted ?? 0))
                    .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.fractionCompleted)
            }
        }
    }
}

// Preview
struct BlobStylesView_Previews: PreviewProvider {
    static var previews: some View {
        BlobStylesView()
    }
}
