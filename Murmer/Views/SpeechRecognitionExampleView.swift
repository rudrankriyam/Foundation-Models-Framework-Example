//
//  SpeechRecognitionExampleView.swift
//  Murmer
//
//  Created by Rudrank Riyam on 6/26/25.
//

import SwiftUI
import AVFoundation

struct SpeechRecognitionExampleView: View {
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var permissionManager = PermissionService()
    @State private var showSettings = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                if permissionManager.allPermissionsGranted {
                    headerSection

                    transcriptionSection

                    controlSection

                    statusSection

                    Spacer()
                } else {
                    permissionSection
                }
            }
            .padding()
            .navigationTitle("Speech Recognition Demo")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                // You could add recognition settings here later
                Text("Speech Recognition Settings")
                    .navigationTitle("Settings")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                permissionManager.checkAllPermissions()
            }
        }
    }

    // MARK: - View Components

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.badge.mic")
                .font(.system(size: 50))
                .foregroundColor(.primary)

            Text("Speech Recognition Demo")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            Text("Tap the microphone to start speaking and see your words appear in real-time")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var transcriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Transcription")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                if !speechRecognizer.state.finalText.isEmpty {
                    Button("Clear") {
                        clearTranscription()
                    }
                    .font(.caption)
                    .foregroundStyle(.blue)
                }
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Partial text (real-time)
                    if speechRecognizer.state.isListening && !speechRecognizer.state.partialText.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Speaking...")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                    .fontWeight(.medium)

                                Spacer()

                                Image(systemName: "waveform")
                                    .foregroundStyle(.orange)
                                    .font(.caption)
                            }

                            Text(speechRecognizer.state.partialText)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .padding()
                                .background(.orange.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    // Final text
                    if !speechRecognizer.state.finalText.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Final Result")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                    .fontWeight(.medium)

                                Spacer()

                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                            }

                            Text(speechRecognizer.state.finalText)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .padding()
                                .background(.green.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .contextMenu {
                                    Button("Copy") {
                                        copyToClipboard(speechRecognizer.state.finalText)
                                    }
                                }
                        }
                    }

                    // Placeholder when empty
                    if !speechRecognizer.state.isListening && speechRecognizer.state.finalText.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "quote.bubble")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary.opacity(0.5))

                            Text("Your speech will appear here")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
            }
            .frame(minHeight: 200)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var controlSection: some View {
        VStack(spacing: 20) {
            Button(action: toggleRecognition) {
                HStack(spacing: 12) {
                    Image(systemName: speechRecognizer.state.isListening ? "stop.fill" : "mic.fill")
                        .font(.title2)

                    Text(speechRecognizer.state.isListening ? "Stop Listening" : "Start Listening")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            speechRecognizer.state.isListening ?
                                Color.red : Color.green
                        )
                }
                .scaleEffect(speechRecognizer.state.isListening ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: speechRecognizer.state.isListening)
            }

            // Recognition tips
            if !speechRecognizer.state.isListening {
                VStack(spacing: 8) {
                    Text("Tips for better recognition:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        tipText("Speak clearly and at normal pace")
                        tipText("Reduce background noise")
                        tipText("Hold device close to your mouth")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var statusSection: some View {
        VStack(spacing: 12) {
            // Current state indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(stateColor)
                    .frame(width: 8, height: 8)

                Text(stateDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()
            }

            // Error display
            if let error = speechRecognizer.state.error {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)

                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.leading)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Character count for final text
            if !speechRecognizer.state.finalText.isEmpty {
                HStack {
                    Spacer()
                    Text("\(speechRecognizer.state.finalText.count) characters")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var permissionSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "mic.slash.fill")
                .font(.system(size: 50))
                .foregroundStyle(.red)

            Text("Permissions Required")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Speech recognition requires microphone and speech recognition permissions.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Grant Permissions") {
                Task {
                    let granted = await permissionManager.requestAllPermissions()

                    if granted {
                        permissionManager.checkAllPermissions()
                    }
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(.blue)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
    }


    // MARK: - Helper Views

    private func tipText(_ text: String) -> some View {
        HStack(spacing: 4) {
            Text("•")
            Text(text)
            Spacer()
        }
    }

    // MARK: - Computed Properties

    private var stateColor: Color {
        switch speechRecognizer.state {
        case .idle:
            return .gray
        case .listening:
            return .orange
        case .completed:
            return .green
        case .error:
            return .red
        }
    }

    private var stateDescription: String {
        switch speechRecognizer.state {
        case .idle:
            return "Ready to listen"
        case .listening:
            return "Listening..."
        case .completed:
            return "Recognition completed"
        case .error:
            return "Recognition error occurred"
        }
    }

    // MARK: - Actions

    private func toggleRecognition() {
        if speechRecognizer.state.isListening {
            speechRecognizer.stopRecognition()
        } else {
            startRecognition()
        }
    }

    private func startRecognition() {
        Task {
            do {
                try speechRecognizer.startRecognition()
            } catch {
                showError(error.localizedDescription)
            }
        }
    }

    private func clearTranscription() {
        // Reset to idle state to clear both partial and final text
        speechRecognizer.stopRecognition()
        // Give it a moment to stop, then reset state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // The state will naturally go to .idle when recognition stops
        }
    }

    private func copyToClipboard(_ text: String) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #elseif os(iOS)
        UIPasteboard.general.string = text
        #endif
    }

    private func showError(_ message: String) {
        errorMessage = message
        showError = true
    }
}

#Preview {
    SpeechRecognitionExampleView()
}