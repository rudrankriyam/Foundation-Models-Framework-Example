//
//  TranscriptEntryView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import SwiftUI
import FoundationModels

struct TranscriptEntryView: View {
    let entry: Transcript.Entry
    @State private var tokenCount: Int?

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
        .task(id: entryContentHash) {
            tokenCount = await resolveTokenCount()
        }
    }

    /// A hash that changes when the entry's text content changes,
    /// ensuring the token count recalculates after streaming completes.
    private var entryContentHash: Int {
        var hasher = Hasher()
        hasher.combine(entry.id)
        hasher.combine(entry.textContent() ?? "")
        return hasher.finalize()
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
                    content: "Calling tool: \(toolCall.toolName)",
                    isFromUser: false
                ))
                .id("\(entry.id)-tool-\(index)")
            }

        case .toolOutput(let toolOutput):
            if let text = toolOutput.segments.textContentJoined() {
                MessageBubbleView(message: ChatMessage(
                    entryID: entry.id,
                    content: "Tool result: \(text)",
                    isFromUser: false
                ))
                .id(entry.id)
            }

        case .instructions:
            EmptyView()

        @unknown default:
            EmptyView()
        }
    }

    private func resolveTokenCount() async -> Int? {
        switch entry {
        case .instructions:
            return nil
        default:
            #if compiler(>=6.3)
            if #available(iOS 26.4, macOS 26.4, visionOS 26.4, *) {
                return try? await SystemLanguageModel.default
                    .tokenUsage(for: [entry]).tokenCount
            }
            #endif
            return entry.estimatedTokenCount
        }
    }
}

private extension Transcript.Entry {
    var isFromUser: Bool {
        if case .prompt = self { return true }
        return false
    }
}
