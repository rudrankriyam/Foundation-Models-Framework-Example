//
//  SettingsView.swift
//  Murmer
//
//  Created by Rudrank Riyam on 6/26/25.
//

import SwiftUI
import AVFoundation

struct SettingsView: View {
    @ObservedObject var speechSynthesizer: SpeechSynthesizer
    @State private var selectedLanguage = "en-US"
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection

                    if !speechSynthesizer.voicesByLanguage.isEmpty {
                        languageSection
                        voiceSection
                    } else {
                        loadingSection
                    }

                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Voice Settings")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            if let currentVoice = speechSynthesizer.selectedVoice {
                selectedLanguage = currentVoice.language
            }
        }
    }

    // MARK: - View Components

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "speaker.wave.3.fill")
                    .font(.title2)
                    .foregroundStyle(.indigo)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Voice Configuration")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("Choose your preferred voice and language")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let currentVoice = speechSynthesizer.selectedVoice {
                HStack(spacing: 8) {
                    Text("Current:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(currentVoice.name)
                        .font(.caption)
                        .fontWeight(.medium)

                    Text("(\(currentVoice.language))")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    qualityBadge(currentVoice.quality)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Languages")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("\(speechSynthesizer.availableLanguages.count) languages available")
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 120), spacing: 8)
            ], spacing: 8) {
                ForEach(speechSynthesizer.availableLanguages, id: \.self) { language in
                    languageCard(language: language)
                }
            }
        }
    }

    private var voiceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Voices")
                    .font(.headline)

                Spacer()

                if let voicesForLanguage = speechSynthesizer.voicesByLanguage[selectedLanguage] {
                    Text("\(voicesForLanguage.count) voices")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(languageDisplayName(selectedLanguage))
                .font(.subheadline)
                .foregroundStyle(.indigo)
                .fontWeight(.medium)

            if let voicesForLanguage = speechSynthesizer.voicesByLanguage[selectedLanguage] {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 280), spacing: 12)
                ], spacing: 12) {
                    ForEach(voicesForLanguage, id: \.identifier) { voice in
                        voiceCard(voice: voice)
                    }
                }
            }
        }
    }

    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading voices...")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Please wait while we discover all available voices on your system")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Helper Views

    private func languageCard(language: String) -> some View {
        Button(action: { selectedLanguage = language }) {
            VStack(spacing: 8) {
                Text(languageDisplayName(language))
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                if let voicesCount = speechSynthesizer.voicesByLanguage[language]?.count {
                    Text("\(voicesCount) voices")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .background(selectedLanguage == language ? Color.indigo.opacity(0.1) : Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedLanguage == language ? .indigo : .clear, lineWidth: 2)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func voiceCard(voice: AVSpeechSynthesisVoice) -> some View {
        Button(action: { speechSynthesizer.selectedVoice = voice }) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(voice.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Text(voice.language)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                qualityBadge(voice.quality)

                if speechSynthesizer.selectedVoice?.identifier == voice.identifier {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.indigo)
                        .font(.title3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(speechSynthesizer.selectedVoice?.identifier == voice.identifier ?
                       Color.indigo.opacity(0.1) : Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(speechSynthesizer.selectedVoice?.identifier == voice.identifier ?
                           Color.indigo : Color.gray.opacity(0.3), lineWidth: 1)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func qualityBadge(_ quality: AVSpeechSynthesisVoiceQuality) -> some View {
        Text(qualityString(quality))
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(qualityColor(quality))
            .clipShape(Capsule())
    }

    // MARK: - Helper Functions

    private func languageDisplayName(_ languageCode: String) -> String {
        let locale = Locale(identifier: languageCode)
        return locale.localizedString(forLanguageCode: languageCode)?.capitalized ?? languageCode
    }


    private func qualityString(_ quality: AVSpeechSynthesisVoiceQuality) -> String {
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

    private func qualityColor(_ quality: AVSpeechSynthesisVoiceQuality) -> Color {
        switch quality {
        case .default:
            return .gray
        case .enhanced:
            return .orange
        case .premium:
            return .indigo
        @unknown default:
            return .gray
        }
    }
}

#Preview {
    SettingsView(speechSynthesizer: SpeechSynthesizer())
}