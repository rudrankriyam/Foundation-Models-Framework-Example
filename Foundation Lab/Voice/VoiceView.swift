//
//  VoiceView.swift
//  Foundation Lab
//
//  Created by Rudrank Riyam on 10/27/25.
//

import SwiftUI

struct VoiceView: View {
    @State private var viewModel = VoiceViewModel()
    @State private var blobScale: CGFloat = 1.0

    var body: some View {
        Group {
            if viewModel.permissionManager.allPermissionsGranted {
                voiceMainView
            } else {
                PermissionRequestView(permissionManager: viewModel.permissionManager)
            }
        }
        .onAppear {
            viewModel.permissionManager.checkAllPermissions()
        }
        .onChange(of: viewModel.permissionManager.allPermissionsGranted) { _, _ in
            // Force view update when permissions change
        }
    }

    private var voiceMainView: some View {
        VStack(spacing: 30) {
            // Header with list selector
            VStack(alignment: .leading, spacing: 16) {
                Text("Voice")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text("Create reminders with your voice")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                GlassDropdown(
                    selectedValue: $viewModel.selectedList,
                    options: viewModel.availableLists,
                    title: "Reminder List"
                )
                .frame(maxWidth: 300)
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            // Main content
            VStack(spacing: 40) {
                // Audio reactive blob placeholder
                ZStack {
                    // Glow effect when listening
                    if viewModel.isListening {
                        Circle()
                            .fill(Color.indigo.opacity(0.2))
                            .frame(width: 400, height: 400)
                            .blur(radius: 30)
                            .animation(
                                .easeInOut(duration: 2).repeatForever(autoreverses: true),
                                value: viewModel.isListening
                            )
                    }

                    AudioReactiveBlobView(
                        speechRecognizer: viewModel.speechRecognizer,
                        listeningState: .init(
                            get: { viewModel.isListening },
                            set: { _ in }
                        )
                    )
                    .frame(width: 250, height: 250)
                    .scaleEffect(blobScale)
                    .onTapGesture {
                        toggleListening()
                    }
                }

                // Transcription display
                if !viewModel.recognizedText.isEmpty || viewModel.isListening {
                    VStack(spacing: 8) {
                        if viewModel.isListening && viewModel.partialText.isEmpty {
                            HStack(spacing: 4) {
                                ForEach(0..<3) { index in
                                    Circle()
                                        .fill(Color.primary.opacity(0.5))
                                        .frame(width: 8, height: 8)
                                        .scaleEffect(viewModel.isListening ? 1.2 : 0.8)
                                        .animation(
                                            .easeInOut(duration: 0.6)
                                                .repeatForever()
                                                .delay(Double(index) * 0.2),
                                            value: viewModel.isListening
                                        )
                                }
                            }
                            .padding()
                        } else {
                            Text(viewModel.partialText.isEmpty ? viewModel.recognizedText : viewModel.partialText)
                                .font(.title3)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.center)
                                .padding()
                                .frame(maxWidth: 300)
                        }
                    }
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.regularMaterial)
                    }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 0.8).combined(with: .opacity)
                    ))
                }

                // Instructions
                if !viewModel.isListening && viewModel.recognizedText.isEmpty {
                    Text("Tap the microphone to start")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .alert(
            "Reminder Created",
            isPresented: Binding(
                get: { !viewModel.lastCreatedReminder.isEmpty },
                set: { newValue in
                    if !newValue {
                        viewModel.lastCreatedReminder = ""
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                viewModel.lastCreatedReminder = ""
            }
        } message: {
            Text("Reminder created: \"\(viewModel.lastCreatedReminder)\"")
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    private func toggleListening() {
        if viewModel.isListening {
            viewModel.stopListening()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                blobScale = 1.0
            }
        } else {
            Task {
                await viewModel.startListening()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    blobScale = 1.2
                }
            }
        }

        // Haptic feedback
        #if os(iOS)
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        #endif
    }
}

#Preview {
    VoiceView()
}