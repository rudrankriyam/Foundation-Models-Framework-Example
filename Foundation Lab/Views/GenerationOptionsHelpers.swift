//
//  GenerationOptionsHelpers.swift
//  Foundation Lab
//
//  Created by Rudrank Riyam on 6/20/25.
//

import Foundation
import FoundationModels
import SwiftUI

extension GenerationOptionsView {
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

    struct GenerationConfig {
        let useSampling: Bool
        let samplingMode: SamplingType
        let topK: Int
        let topP: Double
        let temperature: Double
        let maximumResponseTokens: Int
    }

    func createGenerationOptions(from config: GenerationConfig) -> GenerationOptions {
        let samplingModeOption: GenerationOptions.SamplingMode? = if config.useSampling {
            switch config.samplingMode {
            case .greedy:
                .greedy
            case .topK:
                .random(top: config.topK)
            case .nucleus:
                .random(probabilityThreshold: config.topP)
            }
        } else {
            nil // Let system choose default
        }

        return GenerationOptions(
            sampling: samplingModeOption,
            temperature: config.temperature,
            maximumResponseTokens: config.maximumResponseTokens
        )
    }

    @ViewBuilder
    func temperatureSliderView(binding: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Text("Temperature")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(String(format: "%.2f", binding.wrappedValue))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Slider(value: binding, in: 0.0...2.0, step: 0.1)

            Text("Controls creativity (0.0 = deterministic, 2.0 = very creative)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.thinMaterial, in: .rect(cornerRadius: CornerRadius.small))
    }

    @ViewBuilder
    func maxTokensSliderView(binding: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Text("Maximum Response Tokens")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(binding.wrappedValue)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Slider(value: Binding(
                get: { Double(binding.wrappedValue) },
                set: { binding.wrappedValue = Int($0) }
            ), in: 50...4000, step: 50)

            Text("Maximum number of tokens to generate (up to 4000)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.thinMaterial, in: .rect(cornerRadius: CornerRadius.small))
    }
}
