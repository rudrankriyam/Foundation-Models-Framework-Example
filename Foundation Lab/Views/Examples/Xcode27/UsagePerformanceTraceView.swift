//
//  UsagePerformanceTraceView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import SwiftUI

struct UsagePerformanceTraceView: View {
    @State private var currentPrompt = "Profile the model turn and explain which metric needs attention."
    @State private var trace = UsageTrace.good

    var body: some View {
        ExampleViewBase(
            title: "Usage Trace",
            description: "Read a model turn like an Instruments trace",
            defaultPrompt: "Profile the model turn and explain which metric needs attention.",
            currentPrompt: $currentPrompt,
            codeExample: codeExample,
            onRun: cycleTrace,
            onReset: reset
        ) {
            VStack(spacing: Spacing.medium) {
                Picker("Trace", selection: $trace) {
                    ForEach(UsageTrace.allCases) { trace in
                        Text(trace.title).tag(trace)
                    }
                }
                .pickerStyle(.segmented)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                    Xcode27StatusCard(title: "TTFT", value: trace.ttft, systemImage: "timer", tint: trace.tint)
                    Xcode27StatusCard(title: "Latency", value: trace.latency, systemImage: "speedometer", tint: trace.tint)
                    Xcode27StatusCard(title: "Input", value: trace.inputTokens, systemImage: "arrow.down.doc", tint: .blue)
                    Xcode27StatusCard(title: "Reasoning", value: trace.reasoningTokens, systemImage: "brain", tint: .purple)
                }

                Xcode27Section("Diagnosis", systemImage: "waveform.path.ecg") {
                    Text(trace.diagnosis)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func cycleTrace() {
        let cases = UsageTrace.allCases
        guard let index = cases.firstIndex(of: trace) else { return }
        trace = cases[(index + 1) % cases.count]
    }

    private func reset() {
        currentPrompt = ""
        trace = .good
    }

    private var codeExample: String {
        """
        let response = try await session.respond(
            to: prompt,
            contextOptions: ContextOptions(reasoningLevel: .moderate),
            metadata: ["turn": turnID]
        )

        print(response.usage.input.totalTokenCount)
        print(response.usage.input.cachedTokenCount)
        print(response.usage.output.reasoningTokenCount)
        """
    }
}

private enum UsageTrace: String, CaseIterable, Identifiable {
    case good
    case highInput
    case slowTools

    var id: String { rawValue }

    var title: String {
        switch self {
        case .good: return "Healthy"
        case .highInput: return "Input"
        case .slowTools: return "Tools"
        }
    }

    var ttft: String {
        switch self {
        case .good: return "0.7s"
        case .highInput: return "1.9s"
        case .slowTools: return "0.8s"
        }
    }

    var latency: String {
        switch self {
        case .good: return "2.4s"
        case .highInput: return "6.8s"
        case .slowTools: return "9.1s"
        }
    }

    var inputTokens: String {
        switch self {
        case .good: return "1.8k"
        case .highInput: return "7.4k"
        case .slowTools: return "2.1k"
        }
    }

    var reasoningTokens: String {
        switch self {
        case .good: return "180"
        case .highInput: return "340"
        case .slowTools: return "210"
        }
    }

    var diagnosis: String {
        switch self {
        case .good:
            return "The trace has a short prompt, cached context, and low tool overhead."
        case .highInput:
            return "Most latency comes from oversized input. Add history compaction or narrower tool guidance."
        case .slowTools:
            return "Model streaming starts quickly, but the end-to-end turn waits on slow tools. Inspect tool duration before tuning prompts."
        }
    }

    var tint: Color {
        switch self {
        case .good: return .green
        case .highInput: return .orange
        case .slowTools: return .red
        }
    }
}

#Preview {
    NavigationStack {
        UsagePerformanceTraceView()
    }
}
