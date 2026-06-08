//
//  AgentFlowInspectorView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import SwiftUI

struct AgentFlowInspectorView: View {
    @State private var currentPrompt = "Plan a dinner, check my pantry, and draft a grocery list."
    @State private var selectedStep = AgentFlowStep.profile

    var body: some View {
        ExampleViewBase(
            title: "Agent Flow",
            description: "Inspect one model turn from prompt to response",
            defaultPrompt: "Plan a dinner, check my pantry, and draft a grocery list.",
            currentPrompt: $currentPrompt,
            codeExample: selectedStep.code,
            onRun: advance,
            onReset: reset
        ) {
            VStack(spacing: Spacing.medium) {
                Xcode27Section("Turn Timeline", systemImage: "point.topleft.down.curvedto.point.bottomright.up") {
                    VStack(spacing: 10) {
                        ForEach(AgentFlowStep.allCases) { step in
                            AgentFlowStepRow(step: step, isSelected: step == selectedStep)
                                .onTapGesture { selectedStep = step }
                        }
                    }
                }

                Xcode27Section(selectedStep.title, systemImage: selectedStep.icon) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(selectedStep.detail)
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        AgentFlowDataGrid(items: selectedStep.facts)
                    }
                }
            }
        }
    }

    private func advance() {
        let steps = AgentFlowStep.allCases
        guard let index = steps.firstIndex(of: selectedStep) else { return }
        selectedStep = steps[(index + 1) % steps.count]
    }

    private func reset() {
        currentPrompt = ""
        selectedStep = .profile
    }
}

private struct AgentFlowStepRow: View {
    let step: AgentFlowStep
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: step.icon)
                .foregroundStyle(isSelected ? .white : step.tint)
                .frame(width: 28, height: 28)
                .background(isSelected ? step.tint : Color.clear)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(step.title)
                    .font(.subheadline.weight(.semibold))
                Text(step.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(10)
        .background(isSelected ? step.tint.opacity(0.12) : Color.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct AgentFlowDataGrid: View {
    let items: [(String, String)]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
            ForEach(items, id: \.0) { title, value in
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(value)
                        .font(.subheadline.weight(.medium))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

private enum AgentFlowStep: String, CaseIterable, Identifiable {
    case profile
    case history
    case toolPolicy
    case modelCall
    case toolCall
    case response
    case usage

    var id: String { rawValue }

    var title: String {
        switch self {
        case .profile: return "Profile selected"
        case .history: return "History transformed"
        case .toolPolicy: return "Tool policy"
        case .modelCall: return "Model call"
        case .toolCall: return "Tool call"
        case .response: return "Response"
        case .usage: return "Usage"
        }
    }

    var summary: String {
        switch self {
        case .profile: return "Choose instructions, model, tools, and callbacks"
        case .history: return "Trim, redact, or spotlight transcript entries"
        case .toolPolicy: return "Allowed, required, or disallowed tools"
        case .modelCall: return "Send prompt with generation and context options"
        case .toolCall: return "Review arguments before side effects"
        case .response: return "Render text, structure, and transcript entries"
        case .usage: return "Inspect tokens, latency, and cache behavior"
        }
    }

    var detail: String {
        switch self {
        case .profile:
            return "A DynamicProfile is the control plane for an agent turn. It explains why this mode got these instructions, tools, model, and lifecycle hooks."
        case .history:
            return "History transforms are where context compaction and safety become visible. Show what was kept, dropped, summarized, or marked as untrusted."
        case .toolPolicy:
            return "Tool calling mode should be a product decision. A weather answer may require a tool; a draft may disallow tools."
        case .modelCall:
            return "The model call combines prompt, profile, generation options, context options, and metadata into one auditable request."
        case .toolCall:
            return "Risky tools should pause for confirmation before doing irreversible or user-visible work."
        case .response:
            return "Responses are not just strings. They carry transcript entries, generated content, and usage data that should feed diagnostics."
        case .usage:
            return "Usage closes the loop: token counts, cached tokens, reasoning tokens, and latency tell you whether the flow is healthy."
        }
    }

    var icon: String {
        switch self {
        case .profile: return "person.text.rectangle"
        case .history: return "clock.arrow.circlepath"
        case .toolPolicy: return "hammer"
        case .modelCall: return "brain.head.profile"
        case .toolCall: return "hand.raised"
        case .response: return "text.bubble"
        case .usage: return "speedometer"
        }
    }

    var tint: Color {
        switch self {
        case .profile: return .blue
        case .history: return .purple
        case .toolPolicy: return .orange
        case .modelCall: return .indigo
        case .toolCall: return .red
        case .response: return .green
        case .usage: return .teal
        }
    }

    var facts: [(String, String)] {
        switch self {
        case .profile:
            return [("Mode", "Planning"), ("Model", "System/PCC"), ("Tools", "Pantry, Notes"), ("Callbacks", "onToolCall")]
        case .history:
            return [("Kept", "5 entries"), ("Summarized", "12 entries"), ("Redacted", "2 secrets"), ("Budget saved", "1,840 tokens")]
        case .toolPolicy:
            return [("Mode", "Required"), ("Reason", "Fresh pantry data"), ("Fallback", "Ask user"), ("Risk", "Low")]
        case .modelCall:
            return [("Reasoning", "Moderate"), ("Max output", "600"), ("Metadata", "turn-id"), ("Context", "Compacted")]
        case .toolCall:
            return [("Tool", "createGroceryList"), ("Side effect", "Draft only"), ("Confirmation", "Not needed"), ("Arguments", "Validated")]
        case .response:
            return [("Format", "Checklist"), ("Sources", "Pantry tool"), ("Transcript", "4 new entries"), ("Status", "Rendered")]
        case .usage:
            return [("Input", "2,180"), ("Cached", "740"), ("Output", "420"), ("TTFT", "0.8s")]
        }
    }

    var code: String {
        """
        struct PlanningProfile: LanguageModelSession.DynamicProfile {
            var mode: AgentMode

            var body: some DynamicProfile {
                Profile {
                    PlanningInstructions(mode: mode)
                    PantryTool()
                    GroceryDraftTool()
                }
                .toolCallingMode(mode.requiresFreshData ? .required : .allowed)
                .historyTransform { history in
                    history.compactedForPlanning()
                }
                .onToolCall { call in
                    try await confirmIfRisky(call)
                }
            }
        }
        """
    }
}

#Preview {
    NavigationStack {
        AgentFlowInspectorView()
    }
}
