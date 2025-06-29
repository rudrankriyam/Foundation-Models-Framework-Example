//
//  MetalBlobView.swift
//  Murmer
//
//  Created by Rudrank Riyam on 6/26/25.
//

import SwiftUI

struct MetalBlobView: View {
    @ObservedObject var audioManager: AudioManager
    
    let colorScheme: [Color] = [
        .purple,
        .indigo,
        .blue,
        .cyan
    ]
    
    @State private var morphProgress: Double = 0
    
    var body: some View {
        TimelineView(.animation) { context in
            ZStack {
                // Background layer with mesh gradient
                Rectangle()
                    .fill(
                        MeshGradient(
                            width: 3,
                            height: 3,
                            points: meshPoints(for: context.date.timeIntervalSinceReferenceDate),
                            colors: meshColors()
                        )
                    )
                    .blur(radius: 30)
                
                // Main blob with layer effect
                Circle()
                    .fill(
                        LinearGradient(
                            colors: colorScheme,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(0.8 + audioManager.currentAmplitude * 0.4)
                    .blur(radius: 10)
                    .opacity(0.8)
                
                // Glow overlay
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.3 * audioManager.currentAmplitude),
                                Color.purple.opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .scaleEffect(1.2 + audioManager.currentAmplitude * 0.3)
            }
            .drawingGroup()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                morphProgress = 1
            }
        }
    }
    
    private func meshPoints(for time: Double) -> [SIMD2<Float>] {
        var points: [SIMD2<Float>] = []
        let amplitude = Float(audioManager.currentAmplitude)
        
        for row in 0..<3 {
            for col in 0..<3 {
                let baseX = Float(col) / 2.0
                let baseY = Float(row) / 2.0
                
                // Add organic movement
                let offsetX = sin(Float(time) * 0.5 + Float(row) * 0.3) * 0.1 * amplitude
                let offsetY = cos(Float(time) * 0.7 + Float(col) * 0.4) * 0.1 * amplitude
                
                points.append(SIMD2<Float>(baseX + offsetX, baseY + offsetY))
            }
        }
        
        return points
    }
    
    private func meshColors() -> [Color] {
        var colors: [Color] = []
        let amplitude = audioManager.currentAmplitude
        
        for i in 0..<9 {
            let hue = Double(i) / 9.0 * 0.3 + 0.6 // Purple to blue range
            let saturation = 0.7 + amplitude * 0.3
            let brightness = 0.8 + amplitude * 0.2
            
            colors.append(Color(hue: hue, saturation: saturation, brightness: brightness))
        }
        
        return colors
    }
}