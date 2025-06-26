//
//  BlobShaders.metal
//  Murmer
//
//  Created by Rudrank Riyam on 6/26/25.
//

#include <metal_stdlib>
using namespace metal;

// Liquid blob distortion shader
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

// Noise-based organic distortion
[[ stitchable ]] float2 organicDistortion(float2 position,
                                         float time,
                                         float audioLevel,
                                         float seed) {
    // Simple pseudo-random function
    float random(float2 st) {
        return fract(sin(dot(st.xy, float2(12.9898, 78.233))) * 43758.5453123);
    }
    
    // 2D noise function
    float noise(float2 st) {
        float2 i = floor(st);
        float2 f = fract(st);
        
        float a = random(i);
        float b = random(i + float2(1.0, 0.0));
        float c = random(i + float2(0.0, 1.0));
        float d = random(i + float2(1.0, 1.0));
        
        float2 u = f * f * (3.0 - 2.0 * f);
        
        return mix(a, b, u.x) +
               (c - a) * u.y * (1.0 - u.x) +
               (d - b) * u.x * u.y;
    }
    
    // Apply noise-based distortion
    float2 noiseOffset = float2(
        noise(position * 5.0 + float2(time * 0.5, seed)),
        noise(position * 5.0 + float2(seed, time * 0.5))
    );
    
    // Scale by audio level
    noiseOffset *= 0.1 * (1.0 + audioLevel * 3.0);
    
    return position + noiseOffset;
}

// Color gradient shader with audio reactivity
[[ stitchable ]] half4 audioGradient(float2 position,
                                     half4 color,
                                     float time,
                                     float audioLevel) {
    // Create pulsing effect based on distance from center
    float2 center = float2(0.5, 0.5);
    float distance = length(position - center);
    
    // Pulse with audio
    float pulse = sin(distance * 10.0 - time * 3.0 + audioLevel * 5.0) * 0.5 + 0.5;
    pulse *= audioLevel;
    
    // Modify color brightness and saturation
    half3 hsvColor = color.rgb;
    hsvColor *= (1.0 + pulse * 0.5);
    
    // Add glow effect
    float glow = exp(-distance * 3.0) * audioLevel;
    hsvColor += glow * 0.3;
    
    return half4(hsvColor, color.a);
}

// Frequency visualizer shader
[[ stitchable ]] half4 frequencyVisualizer(float2 position,
                                           half4 color,
                                           float time,
                                           float frequencyBin,
                                           float amplitude) {
    // Map position to frequency bins
    float binPosition = position.x;
    float binDistance = abs(binPosition - frequencyBin);
    
    // Create bar visualization
    float barHeight = amplitude * 0.8;
    float inBar = step(position.y, barHeight) * step(binDistance, 0.02);
    
    // Add glow around bars
    float glow = exp(-binDistance * 50.0) * exp(-(position.y - barHeight) * 10.0);
    glow *= amplitude;
    
    // Mix colors
    half3 barColor = color.rgb * inBar;
    half3 glowColor = color.rgb * glow * 0.5;
    
    return half4(barColor + glowColor, max(inBar, glow * 0.5));
}