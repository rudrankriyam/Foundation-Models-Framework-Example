//
//  TranscriptExplorerView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import SwiftUI

struct TranscriptExplorerView: View {
    @State private var currentPrompt = "Browse the Xcode 27 transcript segment types."
    @State private var selectedSegment = TranscriptSegmentExample.reasoning

    var body: some View {
        ExampleViewBase(
            title: "Transcript Explorer",
            description: "Browse new reasoning, attachment, and custom segment cases",
            defaultPrompt: "Browse the Xcode 27 transcript segment types.",
            currentPrompt: $currentPrompt,
            codeExample: codeExample,
            onRun: {},
            onReset: { currentPrompt = "" }
        ) {
            VStack(spacing: Spacing.medium) {
                Picker("Segment", selection: $selectedSegment) {
                    ForEach(TranscriptSegmentExample.allCases) { segment in
                        Label(segment.title, systemImage: segment.icon)
                            .tag(segment)
                    }
                }
                .pickerStyle(.segmented)

                Xcode27Section(selectedSegment.title, systemImage: selectedSegment.icon) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(selectedSegment.detail)
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        Text(selectedSegment.sample)
                            .font(.body.monospaced())
                            .textSelection(.enabled)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                Xcode27Section("Why this matters", systemImage: "wrench.and.screwdriver") {
                    VStack(alignment: .leading, spacing: 10) {
                        Xcode27InfoRow(
                            title: "Switches need new cases",
                            detail: "Code that walked transcript entries or segments in Xcode 26 should explicitly handle the new Xcode 27 cases.",
                            systemImage: "switch.2"
                        )

                        Xcode27InfoRow(
                            title: "Debug views get richer",
                            detail: "A transcript debugger can now show reasoning, image attachments, generated references, and app-defined custom content.",
                            systemImage: "ladybug"
                        )
                    }
                }
            }
        }
    }

    private var codeExample: String {
        """
        switch segment {
        case .text(let text):
            render(text.content)
        case .structure(let structured):
            render(structured.schemaName)
        case .attachment(let attachment):
            render(attachment.label)
        case .custom(let custom):
            render(custom.description)
        @unknown default:
            render("Unknown segment")
        }
        """
    }
}

private enum TranscriptSegmentExample: String, CaseIterable, Identifiable {
    case reasoning
    case attachment
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reasoning:
            return "Reasoning"
        case .attachment:
            return "Attachment"
        case .custom:
            return "Custom"
        }
    }

    var icon: String {
        switch self {
        case .reasoning:
            return "brain"
        case .attachment:
            return "paperclip"
        case .custom:
            return "puzzlepiece.extension"
        }
    }

    var detail: String {
        switch self {
        case .reasoning:
            return "Xcode 27 adds transcript reasoning entries so developer tools can separate reasoning from ordinary assistant text."
        case .attachment:
            return "Attachment segments let image inputs and generated image references travel through the transcript."
        case .custom:
            return "Custom segments give framework and app integrations room to preserve extra typed transcript content."
        }
    }

    var sample: String {
        switch self {
        case .reasoning:
            return "Transcript.Entry.reasoning(...)"
        case .attachment:
            return "Transcript.Segment.attachment(...)"
        case .custom:
            return "Transcript.Segment.custom(...)"
        }
    }
}

#Preview {
    NavigationStack {
        TranscriptExplorerView()
    }
}

