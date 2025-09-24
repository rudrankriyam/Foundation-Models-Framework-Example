//
//  AudioReactiveBlobView.swift
//  Murmer
//
//  Created by Rudrank Riyam on 6/26/25.
//

import SwiftUI

struct AudioReactiveBlobView: View {
    @ObservedObject var audioManager: AudioManager
    @State private var pulseScale: CGFloat = 1.0
    @State private var isListening = false

    // External binding to sync with view model
    @Binding var listeningState: Bool

    // Minimalist parameters
    private let baseSize: CGFloat = 100
    private let maxScale: CGFloat = 1.2

    init(audioManager: AudioManager, listeningState: Binding<Bool> = .constant(false)) {
        self.audioManager = audioManager
        self._listeningState = listeningState
    }

    var body: some View {
        ZStack {
            // Single clean blob
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.6),
                            Color.purple.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: baseSize * pulseScale, height: baseSize * pulseScale)
                .shadow(color: Color.purple.opacity(0.3), radius: 10, x: 0, y: 5)

            // Subtle inner highlight
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: (baseSize * 0.6) * pulseScale, height: (baseSize * 0.6) * pulseScale)

            // Microphone icon
            Image(systemName: listeningState ? "waveform.badge.mic" : "mic.circle.fill")
                .font(.system(size: 30))
                .foregroundColor(.white)
                .scaleEffect(pulseScale)
        }
        .onChange(of: audioManager.currentAmplitude) { _, amplitude in
            // Gentle pulse based on audio level
            let targetScale = 1.0 + (amplitude * 0.3)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                pulseScale = min(targetScale, maxScale)
            }
        }
        .onChange(of: listeningState) { _, newState in
            // Sync internal state with external binding
            isListening = newState
        }
        .onAppear {
            // Gentle breathing animation when idle
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                pulseScale = 1.05
            }
        }
    }

}

// MARK: - Preview
#Preview {
    @State var isListening = false

    return AudioReactiveBlobView(audioManager: AudioManager(), listeningState: $isListening)
        .frame(width: 150, height: 150)
        .background(Color.gray.opacity(0.1))
        .onTapGesture {
            isListening.toggle()
        }
}
