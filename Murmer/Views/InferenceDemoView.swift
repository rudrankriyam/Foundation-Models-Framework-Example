//
//  InferenceDemoView.swift
//  Murmer
//
//  Created by Rudrank Riyam on 9/24/25.
//

import SwiftUI

struct InferenceDemoView: View {
    @State private var inferenceService = InferenceService()
    @State private var inputText = ""
    @State private var outputText = ""
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI Inference Demo")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("See how the AI processes your requests and creates reminders")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("Current timezone: \(TimeZone.current.identifier) (\(InferenceService.getTimezoneOffsetString()))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                // Input Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Input Text")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    TextEditor(text: $inputText)
                        .frame(height: 100)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.regularMaterial)
                                #if os(iOS) || os(macOS)
                                .glassEffect(.regular, in: .rect(cornerRadius: 12))
                                #endif
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )

                    Text("Try examples:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(sampleInputs, id: \.self) { sample in
                                Button(action: {
                                    inputText = sample
                                }) {
                                    Text(sample)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(20)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // Process Button
                Button(action: processInput) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "brain.head.profile")
                        }
                        Text(isProcessing ? "Processing..." : "Process with AI")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
                .padding(.horizontal)

                // Output Section
                if !outputText.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("AI Response")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(outputText)
                            .font(.body)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.regularMaterial)
                                    #if os(iOS) || os(macOS)
                                    .glassEffect(.regular, in: .rect(cornerRadius: 12))
                                    #endif
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)
                    .transition(.slide)
                }

                Spacer(minLength: 30)
            }
            .padding(.vertical)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func processInput() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        isProcessing = true
        outputText = ""

        Task {
            do {
                let response = try await inferenceService.processText(inputText)
                await MainActor.run {
                    outputText = response
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isProcessing = false
                }
            }
        }
    }

    private let sampleInputs = [
        "Remind me to buy groceries",
        "Call mom tomorrow morning",
        "Pay the electricity bill next week",
        "Pick up dry cleaning today",
        "Schedule dentist appointment for Friday",
        "Send birthday card to uncle"
    ]
}

#Preview {
    InferenceDemoView()
}
