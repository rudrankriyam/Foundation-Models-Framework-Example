//
//  MetalBlobView.swift
//  Murmer
//
//  Created by Rudrank Riyam on 6/26/25.
//

import SwiftUI

struct MetalBlobView: View {
    @ObservedObject var audioManager: AudioManager
    @State private var time: Double = 0
    @State private var morphProgress: Double = 0
    
    private let colorScheme: [Color] = [
        Color(red: 0.5, green: 0.3, blue: 0.9),
        Color(red: 0.3, green: 0.5, blue: 0.95),
        Color(red: 0.6, green: 0.3, blue: 0.85)
    ]
    
    var body: some View {
        TimelineView(.animation) { context in
            ZStack {
                // Background layer with Metal shader
                Rectangle()
                    .foregroundStyle(
                        .mesh(
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
                    .layerEffect(
                        ShaderLibrary.liquidBlob(
                            .float(time),
                            .float(audioManager.currentAmplitude),
                            .float(morphProgress)
                        ),
                        maxSampleOffset: .zero
                    )
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
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .scaleEffect(1.2 + audioManager.currentAmplitude * 0.3)
                    .blur(radius: 20)
            }
            .drawingGroup()
            .onChange(of: context.date) { _, newDate in
                time = newDate.timeIntervalSinceReferenceDate
            }
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

// Metal Shader Library
struct ShaderLibrary {
    static let liquidBlob = ShaderFunction(
        library: .default,
        name: "liquidBlob"
    )
}

// Metal shader code (would be in a separate .metal file)
/*
#include <metal_stdlib>
using namespace metal;

[[ stitchable ]] float2 liquidBlob(float2 position,
                                   float time,
                                   float audioLevel,
                                   float morphProgress) {
    float2 center = float2(0.5, 0.5);
    float2 offset = position - center;
    
    // Create wave distortion
    float angle = atan2(offset.y, offset.x);
    float distance = length(offset);
    
    // Multiple wave frequencies for organic movement
    float wave1 = sin(angle * 3.0 + time * 2.0) * 0.05;
    float wave2 = sin(angle * 5.0 - time * 1.5 + morphProgress * 3.14159) * 0.03;
    float wave3 = sin(angle * 7.0 + time * 3.0) * 0.02;
    
    // Combine waves with audio modulation
    float totalWave = (wave1 + wave2 + wave3) * (1.0 + audioLevel * 2.0);
    
    // Apply radial distortion
    float distortion = 1.0 + totalWave * (1.0 - distance * 2.0);
    
    // Return distorted position
    return center + offset * distortion;
}
*/