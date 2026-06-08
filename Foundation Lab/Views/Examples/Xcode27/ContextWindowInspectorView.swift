//
//  ContextWindowInspectorView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import FoundationModels
import SwiftUI

struct ContextWindowInspectorView: View {
    @State private var currentPrompt = """
    You are a helpful assistant. Explain Foundation Models, then call tools if needed.
    """
    @State private var instructionsTokens = 180
    @State private var promptTokens = 120
    @State private var schemaTokens = 520
    @State private var toolTokens = 740
    @State private var historyTokens = 1_240
    @State private var responseReserveTokens = 600

    private var maxContextSize: Int {
        SystemLanguageModel.default.contextSize
    }

    private var totalTokens: Int {
        instructionsTokens + promptTokens + schemaTokens + toolTokens + historyTokens + responseReserveTokens
    }

    private var usageFraction: Double {
        min(Double(totalTokens) / Double(maxContextSize), 1)
    }

    var body: some View {
        ExampleViewBase(
            title: "Context Window",
            description: "Inspect the pieces that consume a session budget",
            defaultPrompt: "Inspect the context window.",
            currentPrompt: $currentPrompt,
            codeExample: codeExample,
            onRun: rebalance,
            onReset: reset
        ) {
            VStack(spacing: Spacing.medium) {
                Xcode27StatusCard(
                    title: "Current Budget",
                    value: "\(totalTokens) / \(maxContextSize) tokens",
                    systemImage: "chart.bar.xaxis",
                    tint: usageFraction > 0.9 ? .red : usageFraction > 0.75 ? .orange : .green
                )

                TokenUsageBar(
                    currentTokenCount: totalTokens,
                    maxContextSize: maxContextSize,
                    tokenUsageFraction: usageFraction
                )

                Xcode27Section("Token Sources", systemImage: "list.bullet.rectangle") {
                    VStack(spacing: 14) {
                        tokenStepper("Instructions", value: $instructionsTokens, icon: "text.quote")
                        tokenStepper("Prompt", value: $promptTokens, icon: "text.cursor")
                        tokenStepper("Schemas", value: $schemaTokens, icon: "curlybraces")
                        tokenStepper("Tools", value: $toolTokens, icon: "hammer")
                        tokenStepper("History", value: $historyTokens, icon: "clock.arrow.circlepath")
                        tokenStepper("Response reserve", value: $responseReserveTokens, icon: "arrow.down.doc")
                    }
                }

                Xcode27Section("Compaction Trigger", systemImage: "arrow.triangle.2.circlepath") {
                    Text(compactionAdvice)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var compactionAdvice: String {
        switch usageFraction {
        case ..<0.65:
            return "The session has plenty of room. Keep the transcript intact."
        case ..<0.85:
            return "The session is getting warm. Consider summarizing older turns before adding large schemas or tool output."
        default:
            return "The session is close to the context limit. Compact history or start a fresh session before asking for a long response."
        }
    }

    private func tokenStepper(
        _ title: String,
        value: Binding<Int>,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.subheadline.weight(.medium))

                Spacer()

                Text("\(value.wrappedValue) tokens")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Slider(
                value: Binding(
                    get: { Double(value.wrappedValue) },
                    set: { value.wrappedValue = Int($0) }
                ),
                in: 0...2_000,
                step: 20
            )
            .accessibilityLabel(title)
        }
    }

    private func rebalance() {
        let promptEstimate = max(40, currentPrompt.split(separator: " ").count * 2)
        promptTokens = promptEstimate
    }

    private func reset() {
        currentPrompt = ""
        instructionsTokens = 180
        promptTokens = 120
        schemaTokens = 520
        toolTokens = 740
        historyTokens = 1_240
        responseReserveTokens = 600
    }

    private var codeExample: String {
        """
        let model = SystemLanguageModel.default
        let maxContextSize = model.contextSize
        let tokenCount = try await model.tokenCount(for: transcriptEntries)

        if Double(tokenCount) / Double(maxContextSize) > 0.85 {
            // Summarize older entries or start a fresh session.
        }
        """
    }
}

#Preview {
    NavigationStack {
        ContextWindowInspectorView()
    }
}

