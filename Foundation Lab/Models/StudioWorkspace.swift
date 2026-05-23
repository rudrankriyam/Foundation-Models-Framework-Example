//
//  StudioWorkspace.swift
//  Foundation Lab
//
//  Created by Codex on 5/23/26.
//

import Foundation

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
