//
//  AudioReactiveBlobView.swift
//  Murmer
//
//  Created by Rudrank Riyam on 6/26/25.
//

import SwiftUI

struct AudioReactiveBlobView: View {
    @ObservedObject var audioManager: AudioManager
    @State private var phase: Double = 0
    @State private var morphProgress: Double = 0
    
    // Animation parameters
    private let baseRadius: CGFloat = 100
    private let waveAmplitude: CGFloat = 20
    private let numberOfPoints = 8
    
    var body: some View {
        ZStack {
            // Multiple blob layers for depth
            ForEach(0..<3) { layer in
                BlobShape(
                    phase: phase + Double(layer) * 0.5,
                    morphProgress: morphProgress,
                    audioLevel: audioManager.currentAmplitude,
                    numberOfPoints: numberOfPoints,
                    baseRadius: baseRadius - CGFloat(layer * 10),
                    waveAmplitude: waveAmplitude
                )
                .fill(
                    LinearGradient(
                        colors: gradientColors(for: layer),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blur(radius: CGFloat(layer) * 2)
                .opacity(0.7 - Double(layer) * 0.2)
                .scaleEffect(1.0 + audioManager.currentAmplitude * 0.3)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: audioManager.currentAmplitude)
            }
            
            // Glow effect
            BlobShape(
                phase: phase,
                morphProgress: morphProgress,
                audioLevel: audioManager.currentAmplitude,
                numberOfPoints: numberOfPoints,
                baseRadius: baseRadius + 10,
                waveAmplitude: waveAmplitude
            )
            .fill(
                RadialGradient(
                    colors: [
                        Color.purple.opacity(0.3),
                        Color.blue.opacity(0.1),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 50,
                    endRadius: 150
                )
            )
            .blur(radius: 20)
            .opacity(0.5 + audioManager.currentAmplitude * 0.5)
        }
        .drawingGroup() // Optimize performance with Metal rendering
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
            
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                morphProgress = 1
            }
        }
    }
    
    private func gradientColors(for layer: Int) -> [Color] {
        switch layer {
        case 0:
            return [
                Color(red: 0.5, green: 0.3, blue: 0.9),
                Color(red: 0.3, green: 0.5, blue: 0.95),
                Color(red: 0.6, green: 0.3, blue: 0.85)
            ]
        case 1:
            return [
                Color(red: 0.4, green: 0.6, blue: 0.95),
                Color(red: 0.6, green: 0.4, blue: 0.9),
                Color(red: 0.5, green: 0.5, blue: 0.92)
            ]
        default:
            return [
                Color(red: 0.7, green: 0.5, blue: 0.9),
                Color(red: 0.5, green: 0.7, blue: 0.95),
                Color(red: 0.6, green: 0.6, blue: 0.88)
            ]
        }
    }
}

struct BlobShape: Shape {
    var phase: Double
    var morphProgress: Double
    var audioLevel: Double
    var numberOfPoints: Int
    var baseRadius: CGFloat
    var waveAmplitude: CGFloat
    
    var animatableData: AnimatablePair<Double, AnimatablePair<Double, Double>> {
        get {
            AnimatablePair(phase, AnimatablePair(morphProgress, audioLevel))
        }
        set {
            phase = newValue.first
            morphProgress = newValue.second.first
            audioLevel = newValue.second.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let angleStep = (2 * .pi) / Double(numberOfPoints)
        
        var path = Path()
        var points: [CGPoint] = []
        
        // Calculate control points
        for i in 0..<numberOfPoints {
            let angle = Double(i) * angleStep + phase
            
            // Create organic variation
            let radiusVariation = sin(angle * 3 + morphProgress * .pi * 2) * waveAmplitude
            let audioModulation = audioLevel * waveAmplitude * 2
            let radius = baseRadius + radiusVariation + CGFloat(audioModulation)
            
            let x = center.x + cos(angle) * radius
            let y = center.y + sin(angle) * radius
            
            points.append(CGPoint(x: x, y: y))
        }
        
        // Create smooth blob using cubic Bezier curves
        path.move(to: points[0])
        
        for i in 0..<numberOfPoints {
            let nextIndex = (i + 1) % numberOfPoints
            let prevIndex = (i - 1 + numberOfPoints) % numberOfPoints
            
            // Calculate control points for smooth curves
            let currentPoint = points[i]
            let nextPoint = points[nextIndex]
            
            // Tangent calculation for smooth curves
            let prevPoint = points[prevIndex]
            let nextNextPoint = points[(nextIndex + 1) % numberOfPoints]
            
            let tangent1 = CGPoint(
                x: (nextPoint.x - prevPoint.x) * 0.25,
                y: (nextPoint.y - prevPoint.y) * 0.25
            )
            
            let tangent2 = CGPoint(
                x: (nextNextPoint.x - currentPoint.x) * 0.25,
                y: (nextNextPoint.y - currentPoint.y) * 0.25
            )
            
            let controlPoint1 = CGPoint(
                x: currentPoint.x + tangent1.x,
                y: currentPoint.y + tangent1.y
            )
            
            let controlPoint2 = CGPoint(
                x: nextPoint.x - tangent2.x,
                y: nextPoint.y - tangent2.y
            )
            
            path.addCurve(
                to: nextPoint,
                control1: controlPoint1,
                control2: controlPoint2
            )
        }
        
        path.closeSubpath()
        return path
    }
}

// Preview support
struct AudioReactiveBlobView_Previews: PreviewProvider {
    static var previews: some View {
        AudioReactiveBlobView(audioManager: AudioManager())
            .frame(width: 300, height: 300)
            .background(Color.black)
    }
}