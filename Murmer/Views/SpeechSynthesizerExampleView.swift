//
//  SpeechSynthesizerExampleView.swift
//  Murmer
//
//  Created by Rudrank Riyam on 6/26/25.
//

import SwiftUI
import AVFoundation

#if os(macOS)
import AppKit
#endif

struct SpeechSynthesizerExampleView: View {
    @StateObject private var speechSynthesizer = SpeechSynthesizer()
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSettings = false

    private let sampleTexts = [
        "Hello! Welcome to Murmer, your intelligent voice assistant. This is a demonstration of our speech synthesis capabilities.",
        "The quick brown fox jumps over the lazy dog. This pangram contains every letter of the alphabet at least once.",
        "Technology is best when it brings people together. Today we're exploring the fascinating world of speech synthesis.",
        "In a world where artificial intelligence meets human creativity, amazing things happen. Let's see what we can build together."
    ]

    @State private var selectedTextIndex = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                headerSection

                textSelectionSection

                currentVoiceSection

                audioControlSection

                statusSection

                Spacer()
            }
            .padding()
            .navigationTitle("Speech Synthesizer Demo")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(speechSynthesizer: speechSynthesizer)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - View Components

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 50))
                .foregroundColor(.primary)

            Text("Speech Synthesis Demo")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            Text("Select text below and tap 'Synthesize & Play' to hear it spoken")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var textSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sample Texts")
                .font(.headline)
                .foregroundStyle(.primary)

            Picker("Select Text", selection: $selectedTextIndex) {
                ForEach(0..<sampleTexts.count, id: \.self) { index in
                    Text("Sample \(index + 1)")
                        .tag(index)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            Text(sampleTexts[selectedTextIndex])
                .font(.body)
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.regularMaterial)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.tertiary, lineWidth: 1)
                }
        }
    }

    private var currentVoiceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Current Voice")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                Button(action: { showSettings = true }) {
                    HStack(spacing: 6) {
                        Text("Change")
                            .font(.caption)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .foregroundStyle(.blue)
                }
            }

            if let voice = speechSynthesizer.selectedVoice {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(voice.name)
                            .font(.body)
                            .fontWeight(.medium)

                        Text(voice.language)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    voiceQualityBadge(voice.quality)
                }
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.regularMaterial)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.tertiary, lineWidth: 1)
                }
            } else {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading voices...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
        }
    }

    private func voiceQualityBadge(_ quality: AVSpeechSynthesisVoiceQuality) -> some View {
        Text(voiceQualityString(quality))
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(voiceQualityColor(quality))
            .clipShape(Capsule())
    }

    private func voiceQualityString(_ quality: AVSpeechSynthesisVoiceQuality) -> String {
        switch quality {
        case .default:
            return "Standard"
        case .enhanced:
            return "Enhanced"
        case .premium:
            return "Premium"
        @unknown default:
            return "Unknown"
        }
    }

    private func voiceQualityColor(_ quality: AVSpeechSynthesisVoiceQuality) -> Color {
        switch quality {
        case .default:
            return .gray
        case .enhanced:
            return .orange
        case .premium:
            return .green
        @unknown default:
            return .gray
        }
    }

    private var audioControlSection: some View {
        VStack(spacing: 20) {
            Button(action: synthesizeAndSpeak) {
                HStack(spacing: 8) {
                    Image(systemName: speechSynthesizer.isSpeaking ? "stop.fill" : "play.fill")
                    Text(speechSynthesizer.isSpeaking ? "Speaking..." : "Speak Text")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            speechSynthesizer.isSpeaking ? Color.orange : Color.blue
                        )
                }
            }
            .disabled(speechSynthesizer.isSpeaking)
        }
    }

    private var statusSection: some View {
        VStack(spacing: 8) {
            if speechSynthesizer.isSpeaking {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Speaking...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let error = speechSynthesizer.error {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text("Error: \(error.localizedDescription)")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
    }


    // MARK: - Actions

    private func synthesizeAndSpeak() {
        let textToSynthesize = sampleTexts[selectedTextIndex]

        Task {
            do {
                try await speechSynthesizer.synthesizeAndSpeak(text: textToSynthesize)
            } catch {
                await MainActor.run {
                    self.showError(error.localizedDescription)
                }
            }
        }
    }

    private func showError(_ message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Preview

#Preview {
    SpeechSynthesizerExampleView()
}
