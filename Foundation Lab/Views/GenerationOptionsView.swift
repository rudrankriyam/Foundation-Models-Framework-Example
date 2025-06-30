//
//  GenerationOptionsView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/20/25.
//

import SwiftUI
import FoundationModels

struct GenerationOptionsView: View {
    @State private var temperature: Double = 0.7
    @State private var topK: Int = 50
    @State private var topP: Double = 0.9
    @State private var maximumResponseTokens: Int = 500
    @State private var useSampling: Bool = true
    @State private var samplingMode: SamplingType = .nucleus

    @State private var prompt: String = "Write a creative story about a magical forest"
    @State private var response: String = ""
    @State private var isGenerating: Bool = false
    @State private var showError: String?

    @Namespace private var glassNamespace

    enum SamplingType: String, CaseIterable {
        case greedy = "Greedy"
        case topK = "Top-K"
        case nucleus = "Nucleus (Top-P)"

        var description: String {
            switch self {
            case .greedy:
                return "Always picks the most likely token"
            case .topK:
                return "Considers a fixed number of high-probability tokens"
            case .nucleus:
                return "Considers variable tokens based on probability threshold"
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerView
                promptSection
                optionsSection
                generateSection
                responseSection
            }
            .padding()
        }
        .navigationTitle("Generation Options")
    }

    // MARK: - View Components

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Experiment with Generation Parameters")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Adjust these parameters to see how they affect the model's creativity and output quality.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Prompt")
                .font(.headline)

            TextField("Enter your prompt...", text: $prompt, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
        }
    }

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Generation Parameters")
                .font(.headline)

            VStack(spacing: 16) {
                // Temperature
                temperatureSlider
                
                // Sampling Section
                samplingSection
                
                // Max Response Tokens
                maxTokensSlider
            }
        }
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
    }

    private var temperatureSlider: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Temperature")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(String(format: "%.2f", temperature))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Slider(value: $temperature, in: 0.0...2.0, step: 0.1)

            Text("Controls creativity (0.0 = deterministic, 2.0 = very creative)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.thinMaterial, in: .rect(cornerRadius: 8))
    }
    
    private var samplingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sampling Strategy")
                .font(.subheadline)
                .fontWeight(.medium)

            VStack(alignment: .leading, spacing: 8) {
                Toggle("Use Custom Sampling", isOn: $useSampling)
                    .font(.caption)

                if useSampling {
                    Picker("Sampling Mode", selection: $samplingMode) {
                        ForEach(SamplingType.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(samplingMode.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if samplingMode == .topK {
                        HStack {
                            Text("Top-K Value")
                                .font(.caption)
                            Spacer()
                            Text("\(topK)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: Binding(
                            get: { Double(topK) },
                            set: { topK = Int($0) }
                        ), in: 1...100, step: 1)
                    } else if samplingMode == .nucleus {
                        HStack {
                            Text("Probability Threshold")
                                .font(.caption)
                            Spacer()
                            Text(String(format: "%.2f", topP))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $topP, in: 0.1...1.0, step: 0.05)
                    }
                }
            }
        }
        .padding()
        .background(.thinMaterial, in: .rect(cornerRadius: 8))
    }

    private var maxTokensSlider: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Maximum Response Tokens")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(maximumResponseTokens)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Slider(value: Binding(
                get: { Double(maximumResponseTokens) },
                set: { maximumResponseTokens = Int($0) }
            ), in: 50...4000, step: 50)

            Text("Maximum number of tokens to generate (up to 4000)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.thinMaterial, in: .rect(cornerRadius: 8))
    }

    private var generateSection: some View {
        Button(action: generateResponse) {
            HStack {
                if isGenerating {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "sparkles")
                }
                Text(isGenerating ? "Generating..." : "Generate Response")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .buttonStyle(.glass)
        .disabled(isGenerating || prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isGenerating)
    }

    @ViewBuilder
    private var responseSection: some View {
        if !response.isEmpty || showError != nil {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Generated Response")
                        .font(.headline)
                    Spacer()
                    Button("Clear") {
                        response = ""
                        showError = nil
                    }
                    .buttonStyle(.glass)
                    .font(.caption)
                }

                if let error = showError {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                } else if !response.isEmpty {
                    ScrollView {
                        Text(response)
                            .font(.body)
                            .textSelection(.enabled)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 300)
                    .background(.regularMaterial, in: .rect(cornerRadius: 12))
                }
            }
        }
    }

    // MARK: - Actions

    private func generateResponse() {
        Task {
            await performGeneration()
        }
    }

    @MainActor
    private func performGeneration() async {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        isGenerating = true
        showError = nil
        response = ""

        do {
            // Create sampling mode based on selection
            let samplingMode: GenerationOptions.SamplingMode? = if useSampling {
                switch self.samplingMode {
                case .greedy:
                    .greedy
                case .topK:
                    .random(top: topK)
                case .nucleus:
                    .random(probabilityThreshold: topP)
                }
            } else {
                nil // Let system choose default
            }

            let options = GenerationOptions(
                sampling: samplingMode,
                temperature: temperature,
                maximumResponseTokens: maximumResponseTokens
            )

            let session = LanguageModelSession()
            let generatedResponse = try await session.respond(
                to: Prompt(prompt),
                options: options
            )

            response = generatedResponse.content
        } catch {
            showError = error.localizedDescription
        }

        isGenerating = false
    }
}

#Preview {
    GenerationOptionsView()
}