//
//  ModelRouterDashboardView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import SwiftUI

struct ModelRouterDashboardView: View {
    @State private var currentPrompt = "Choose the right runtime for a long visual reasoning task."
    @State private var selectedWorkload = RouterWorkload.visualReasoning

    var body: some View {
        ExampleViewBase(
            title: "Model Router",
            description: "Explain why a runtime was selected",
            defaultPrompt: "Choose the right runtime for a long visual reasoning task.",
            currentPrompt: $currentPrompt,
            codeExample: selectedWorkload.code,
            onRun: cycleWorkload,
            onReset: reset
        ) {
            VStack(spacing: Spacing.medium) {
                Picker("Workload", selection: $selectedWorkload) {
                    ForEach(RouterWorkload.allCases) { workload in
                        Text(workload.title).tag(workload)
                    }
                }
                .pickerStyle(.segmented)

                Xcode27StatusCard(
                    title: "Selected Runtime",
                    value: selectedWorkload.selectedRuntime,
                    systemImage: "arrow.triangle.branch",
                    tint: selectedWorkload.tint
                )

                Xcode27Section("Runtime Matrix", systemImage: "tablecells") {
                    VStack(spacing: 10) {
                        ForEach(RuntimeCandidate.samples) { candidate in
                            RuntimeCandidateRow(candidate: candidate, workload: selectedWorkload)
                        }
                    }
                }

                Xcode27Section("Routing Explanation", systemImage: "lightbulb") {
                    Text(selectedWorkload.reason)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func cycleWorkload() {
        let cases = RouterWorkload.allCases
        guard let index = cases.firstIndex(of: selectedWorkload) else { return }
        selectedWorkload = cases[(index + 1) % cases.count]
    }

    private func reset() {
        currentPrompt = ""
        selectedWorkload = .visualReasoning
    }
}

private struct RuntimeCandidateRow: View {
    let candidate: RuntimeCandidate
    let workload: RouterWorkload

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: candidate.icon)
                .foregroundStyle(candidate.name == workload.selectedRuntime ? workload.tint : .secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(candidate.name)
                    .font(.subheadline.weight(.semibold))
                Text(candidate.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(candidate.badge)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.10))
                .clipShape(Capsule())
        }
    }
}

private struct RuntimeCandidate: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    let badge: String
    let icon: String

    static let samples = [
        RuntimeCandidate(name: "System", detail: "Fast, private, lower context budget.", badge: "Local", icon: "iphone"),
        RuntimeCandidate(name: "PCC", detail: "Larger model surface with service and quota gates.", badge: "Cloud", icon: "icloud"),
        RuntimeCandidate(name: "Core AI", detail: "App-bundled open model through LanguageModelSession.", badge: "Custom", icon: "shippingbox"),
        RuntimeCandidate(name: "Provider", detail: "Third-party or server executor with custom metadata.", badge: "Executor", icon: "server.rack")
    ]
}

private enum RouterWorkload: String, CaseIterable, Identifiable {
    case visualReasoning
    case privateDraft
    case bundledModel

    var id: String { rawValue }

    var title: String {
        switch self {
        case .visualReasoning: return "Visual"
        case .privateDraft: return "Private"
        case .bundledModel: return "Bundled"
        }
    }

    var selectedRuntime: String {
        switch self {
        case .visualReasoning: return "PCC"
        case .privateDraft: return "System"
        case .bundledModel: return "Core AI"
        }
    }

    var reason: String {
        switch self {
        case .visualReasoning: return "The task needs image understanding, deeper reasoning, and a larger budget. Prefer PCC when available, then fall back clearly."
        case .privateDraft: return "The prompt is personal and short. Keep it on device unless the user opts into another runtime."
        case .bundledModel: return "The app ships a specialized model. Use Core AI through the shared LanguageModel interface."
        }
    }

    var tint: Color {
        switch self {
        case .visualReasoning: return .blue
        case .privateDraft: return .green
        case .bundledModel: return .purple
        }
    }

    var code: String {
        """
        enum RuntimeChoice {
            case system
            case privateCloudCompute
            case coreAI(URL)
        }

        let model: any LanguageModel = switch choice {
        case .system:
            SystemLanguageModel.default
        case .privateCloudCompute:
            PrivateCloudComputeLanguageModel()
        case .coreAI(let url):
            try await CoreAILanguageModel(resourcesAt: url)
        }

        let session = LanguageModelSession(model: model)
        """
    }
}

#Preview {
    NavigationStack {
        ModelRouterDashboardView()
    }
}
