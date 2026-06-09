//
//  TranscriptEntryView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import SwiftUI
import FoundationLabCore
import FoundationModels

struct TranscriptEntryView: View {
    let entry: Transcript.Entry
    @State private var tokenCount: Int?
    @Environment(ChatViewModel.self) private var chatViewModel

    var body: some View {
        VStack(spacing: 2) {
            entryContent

            if let tokenCount {
                Text("\(tokenCount) tokens")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(
                        maxWidth: .infinity,
                        alignment: entry.isFromUser ? .trailing : .leading
                    )
                    .padding(.horizontal, Spacing.large)
            }
        }
        .task(id: entry.id) {
            tokenCount = nil
            tokenCount = await resolveTokenCount()
        }
    }

    @ViewBuilder
    private var entryContent: some View {
        switch entry {
        case .prompt(let prompt):
            if let text = prompt.segments.textContentJoined() {
                MessageBubbleView(message: ChatMessage(content: text, isFromUser: true))
                    .id(entry.id)
            }

        case .response(let response):
            if let text = response.segments.textContentJoined() {
                MessageBubbleView(message: ChatMessage(entryID: entry.id, content: text, isFromUser: false))
                    .id(entry.id)
            }

        case .toolCalls(let toolCalls):
            ForEach(Array(toolCalls.enumerated()), id: \.offset) { index, toolCall in
                MessageBubbleView(message: ChatMessage(
                    entryID: entry.id,
                    content: "🔧 Calling tool: \(toolCall.toolName)",
                    isFromUser: false
                ))
                .id("\(entry.id)-tool-\(index)")
            }

        case .toolOutput(let toolOutput):
            if let text = toolOutput.segments.textContentJoined() {
                MessageBubbleView(message: ChatMessage(
                    entryID: entry.id,
                    content: "🔧 Tool result: \(text)",
                    isFromUser: false
                ))
                .id(entry.id)
            }

        #if compiler(>=6.4)
        case .reasoning(let reasoning):
            if chatViewModel.showsReasoningTrace {
                if #available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *) {
                    ReasoningTraceView(reasoning: reasoning)
                        .id(entry.id)
                }
            }
        #endif

        case .instructions:
            EmptyView()

        @unknown default:
            EmptyView()
        }
    }

    private func resolveTokenCount() async -> Int? {
        if case .instructions = entry {
            return nil
        }

        // Avoid repeatedly calling the tokenizer while the newest entry is still streaming.
        if chatViewModel.session.isResponding,
           chatViewModel.session.transcript.last?.id == entry.id {
            await waitForStreamingToFinish()
        }

        // Always compute tokens from the latest version of the entry in the transcript.
        let latestEntry = chatViewModel.session.transcript.first(where: { $0.id == entry.id }) ?? entry
        return await tokenCount(for: latestEntry)
    }

    private func waitForStreamingToFinish() async {
        while chatViewModel.session.isResponding, !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 150_000_000)
        }

        // Give the transcript a moment to publish its final segment.
        try? await Task.sleep(nanoseconds: 50_000_000)
    }

    private func tokenCount(for entry: Transcript.Entry) async -> Int? {
        await entry.foundationLabTokenCount()
    }
}

#if compiler(>=6.4)
@available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
private struct ReasoningTraceView: View {
    let reasoning: Transcript.Reasoning

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(spacing: Spacing.small) {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(.purple)

                Text("Reasoning Trace")
                    .font(.subheadline.weight(.semibold))

                Spacer()

                if reasoning.signature != nil {
                    Text("Signed")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.purple.opacity(0.12), in: .capsule)
                }
            }

            Text(traceText)
                .font(.callout)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.purple.opacity(0.08), in: .rect(cornerRadius: CornerRadius.large))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .stroke(.purple.opacity(0.18), lineWidth: 1)
        }
        .padding(.horizontal, Spacing.medium)
    }

    private var traceText: String {
        if let text = reasoning.segments.textContentJoined() {
            return text
        }

        if reasoning.signature != nil {
            return "The model provided an opaque reasoning signature, but no readable reasoning text."
        }

        return "No readable reasoning trace was included in this transcript entry."
    }
}
#endif

private extension Transcript.Entry {
    var isFromUser: Bool {
        if case .prompt = self { return true }
        return false
    }
}
