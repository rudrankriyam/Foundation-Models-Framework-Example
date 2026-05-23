//
//  StudioWorkspace.swift
//  Foundation Lab
//
//  Created by Codex on 5/23/26.
//

import Foundation
import FoundationLabCore

enum StudioWorkspace: String, CaseIterable, Identifiable {
    case promptTesting
    case structuredOutput
    case benchmarkRuns
    case capabilityMatrix

    var id: Self { self }

    var title: String {
        switch self {
        case .promptTesting:
            return "Prompt Testing"
        case .structuredOutput:
            return "Structured Output"
        case .benchmarkRuns:
            return "Benchmark Runs"
        case .capabilityMatrix:
            return "Capability Matrix"
        }
    }

    var subtitle: String {
        switch self {
        case .promptTesting:
            return "Compare instructions, sampling, and prompt variants."
        case .structuredOutput:
            return "Validate generated values against dynamic schemas."
        case .benchmarkRuns:
            return "Run repeatable suites with latency and quality signals."
        case .capabilityMatrix:
            return "Map model behavior across tasks, tools, and languages."
        }
    }

    var icon: String {
        switch self {
        case .promptTesting:
            return "text.bubble"
        case .structuredOutput:
            return "checklist.checked"
        case .benchmarkRuns:
            return "speedometer"
        case .capabilityMatrix:
            return "square.grid.3x3"
        }
    }

    var status: String {
        switch self {
        case .promptTesting:
            return "First Slice"
        case .structuredOutput:
            return "Next"
        case .benchmarkRuns:
            return "Planned"
        case .capabilityMatrix:
            return "Planned"
        }
    }

    var metricTitle: String {
        switch self {
        case .promptTesting:
            return "Variants"
        case .structuredOutput:
            return "Schemas"
        case .benchmarkRuns:
            return "Suites"
        case .capabilityMatrix:
            return "Axes"
        }
    }

    var metricValue: String {
        switch self {
        case .promptTesting:
            return "4"
        case .structuredOutput:
            return "8"
        case .benchmarkRuns:
            return "3"
        case .capabilityMatrix:
            return "6"
        }
    }

    var checkpoints: [String] {
        switch self {
        case .promptTesting:
            return [
                "Prompt set editor",
                "Generation options matrix",
                "Side-by-side run history"
            ]
        case .structuredOutput:
            return [
                "Schema picker",
                "Validation failures",
                "Repair prompt tracking"
            ]
        case .benchmarkRuns:
            return [
                "Dataset import",
                "Repeatable run config",
                "Latency and token timeline"
            ]
        case .capabilityMatrix:
            return [
                "Use-case profiles",
                "Language coverage",
                "Tool-call reliability"
            ]
        }
    }
}

enum StudioPipelineStage: String, CaseIterable, Identifiable {
    case settings
    case runs
    case evaluation
    case preview
    case output

    var id: Self { self }

    var title: String {
        switch self {
        case .settings:
            return "Settings"
        case .runs:
            return "Runs"
        case .evaluation:
            return "Evaluation"
        case .preview:
            return "Preview"
        case .output:
            return "Output"
        }
    }

    var systemImage: String {
        switch self {
        case .settings:
            return "slider.horizontal.3"
        case .runs:
            return "play.circle"
        case .evaluation:
            return "chart.bar.doc.horizontal"
        case .preview:
            return "eye"
        case .output:
            return "square.and.arrow.up"
        }
    }
}

struct StudioRunSummary: Identifiable {
    let id = UUID()
    let name: String
    let score: String
    let detail: String

    static let samples = [
        StudioRunSummary(
            name: "Recipe JSON schema",
            score: "92%",
            detail: "Valid structure across short and detailed prompts"
        ),
        StudioRunSummary(
            name: "Travel assistant tone",
            score: "A-",
            detail: "Best result used concise role instructions"
        ),
        StudioRunSummary(
            name: "Tool routing smoke test",
            score: "18 ms",
            detail: "Median setup overhead before generation"
        )
    ]
}

struct StudioActivityEvent: Identifiable {
    let id: String
    let title: String
    let detail: String
    let date: Date
}

enum StudioPromptVariant: String, CaseIterable, Identifiable {
    case baseline
    case concise
    case structured
    case productTone

    var id: Self { self }

    var title: String {
        switch self {
        case .baseline:
            return "Baseline"
        case .concise:
            return "Concise"
        case .structured:
            return "Structured"
        case .productTone:
            return "Product Tone"
        }
    }

    var subtitle: String {
        switch self {
        case .baseline:
            return "Plain prompt with default instructions."
        case .concise:
            return "Short, direct answer with low temperature."
        case .structured:
            return "Answer with a summary and validation notes."
        case .productTone:
            return "Useful answer written like a developer tool."
        }
    }

    var systemPrompt: String? {
        switch self {
        case .baseline:
            return nil
        case .concise:
            return "Answer directly. Prefer concrete wording and avoid filler."
        case .structured:
            return "Return a clear answer with sections: Summary, Details, and Validation Notes."
        case .productTone:
            return "You are helping an Apple platforms developer evaluate local Foundation Models behavior. Be practical, specific, and product-minded."
        }
    }

    var generationOptions: FoundationLabGenerationOptions {
        switch self {
        case .baseline:
            return FoundationLabGenerationOptions(maximumResponseTokens: 260)
        case .concise:
            return FoundationLabGenerationOptions(
                sampling: .greedy,
                temperature: 0.2,
                maximumResponseTokens: 180
            )
        case .structured:
            return FoundationLabGenerationOptions(
                sampling: .randomProbabilityThreshold(0.85),
                temperature: 0.5,
                maximumResponseTokens: 360
            )
        case .productTone:
            return FoundationLabGenerationOptions(
                sampling: .randomTop(40),
                temperature: 0.7,
                maximumResponseTokens: 320
            )
        }
    }
}

struct StudioPromptRun: Identifiable, Hashable {
    let id = UUID()
    let variant: StudioPromptVariant
    let prompt: String
    let output: String
    let duration: TimeInterval
    let tokenCount: Int?
    let finishedAt: Date

    var durationLabel: String {
        duration.formatted(.number.precision(.fractionLength(2))) + "s"
    }

    var tokenLabel: String {
        guard let tokenCount else { return "No token count" }
        return "\(tokenCount) tokens"
    }
}
