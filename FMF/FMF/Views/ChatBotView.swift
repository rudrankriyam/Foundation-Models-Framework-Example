//
//  ChatBotView.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/9/25.
//

import SwiftUI
import FoundationModels

struct ChatBotView: View {
    @State private var viewModel = ChatBotViewModel()
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerView

                messagesView

                inputView
            }
            .navigationTitle("AI ChatBot")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Clear") {
                        viewModel.clearChat()
                    }
                    .disabled(viewModel.session.transcript.entries.isEmpty)
                }
            }
        }
    }

    // MARK: - View Components

    private var headerView: some View {
        VStack(spacing: 8) {
            if viewModel.isSummarizing {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundStyle(.orange)
                    Text("Analyzing conversation context...")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Spacer()
                }
            } else if viewModel.sessionCount > 1 {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(.orange)
                    Text("Session \(viewModel.sessionCount) (Context refreshed)")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.session.transcript.entries) { entry in
                        TranscriptEntryView(entry: entry)
                            .id(entry.id)
                    }

                    if viewModel.isSummarizing {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Summarizing conversation...")
                                .font(.caption)
                                .foregroundStyle(.orange)
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .onChange(of: viewModel.session.transcript.entries.count) { _, _ in
                if let lastEntry = viewModel.session.transcript.entries.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastEntry.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var inputView: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 12) {
                TextField("Type your message...", text: $messageText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .focused($isTextFieldFocused)
                    .lineLimit(1...4)
                    .onSubmit {
                        sendMessage()
                    }

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(
                            messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                }
                .disabled(
                    messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading
                    || viewModel.isSummarizing
                )
            }
            .padding()
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Actions

    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }

        messageText = ""
        isTextFieldFocused = false

        Task {
            await viewModel.sendMessage(trimmedMessage)
        }
    }
}

struct TranscriptEntryView: View {
    let entry: Transcript.Entry
    
    var body: some View {
        switch entry {
        case .prompt(let prompt):
            if let text = extractText(from: prompt.segments), !text.isEmpty {
                MessageBubbleView(message: ChatMessage(content: text, isFromUser: true))
            }
            
        case .response(let response):
            if let text = extractText(from: response.segments), !text.isEmpty {
                MessageBubbleView(message: ChatMessage(content: text, isFromUser: false))
            }
            
        case .toolCalls(let toolCalls):
            ForEach(Array(toolCalls.enumerated()), id: \.offset) { _, toolCall in
                MessageBubbleView(message: ChatMessage(
                    content: "🔧 Calling tool: \(toolCall.toolName)",
                    isFromUser: false
                ))
            }
            
        case .toolOutput(let toolOutput):
            if let text = extractText(from: toolOutput.segments), !text.isEmpty {
                MessageBubbleView(message: ChatMessage(
                    content: "🔧 Tool result: \(text)",
                    isFromUser: false
                ))
            }
            
        case .instructions:
            // Don't show instructions in chat UI
            EmptyView()
            
        @unknown default:
            EmptyView()
        }
    }
    
    private func extractText(from segments: [Transcript.Segment]) -> String? {
        let text = segments.compactMap { segment in
            if case .text(let textSegment) = segment {
                return textSegment.content
            }
            return nil
        }.joined(separator: " ")
        
        return text.isEmpty ? nil : text
    }
}

#Preview {
    ChatBotView()
}
