//
//  ChatView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/9/25.
//

import SwiftUI
import FoundationModels

struct ChatView: View {
    @Binding var viewModel: ChatViewModel
    @State private var scrollID: String?
    @State private var messageText = ""
    @State private var showInstructions = false
    @State private var showFeedbackSheet = false
    @State private var selectedEntryForFeedback: Transcript.Entry?
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            instructionsView

            messagesView

            ChatInputView(
                messageText: $messageText,
                isTextFieldFocused: $isTextFieldFocused
            )
        }
        .environment(viewModel)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { showFeedbackSheet = true }) {
                    Label("Feedback", systemImage: "bubble.left.and.exclamationmark.bubble.right")
                }
                .disabled(viewModel.session.transcript.isEmpty)
                .help("Provide feedback on responses")

                Button("Clear") {
                    viewModel.clearChat()
                }
                .disabled(viewModel.session.transcript.isEmpty)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.dismissError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
        .onAppear {
            // Auto-focus when chat appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
        .sheet(isPresented: $showFeedbackSheet) {
            FeedbackView(
                viewModel: viewModel,
                selectedEntry: $selectedEntryForFeedback,
                isPresented: $showFeedbackSheet
            )
#if os(macOS)
            .frame(minWidth: 600, minHeight: 400)
#endif
        }
    }


    // MARK: - View Components

    private var instructionsView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { showInstructions.toggle() }) {
                HStack(spacing: Spacing.small) {
                    Image(systemName: showInstructions ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text("Instructions")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Spacer()

                    if !showInstructions {
                        Text("Customize AI behavior")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.small)
            }
            .buttonStyle(.plain)

            if showInstructions {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    TextEditor(text: $viewModel.instructions)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .padding(Spacing.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)

                    HStack {
                        Text("Changes will apply to new conversations")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Button("Apply Now") {
                            viewModel.updateInstructions(viewModel.instructions)
                            viewModel.clearChat()
                            showInstructions = false
                        }
                        .font(.caption)
                        .fontWeight(.medium)
#if os(iOS) || os(macOS)
                        .buttonStyle(.glassProminent)
#else
                        .buttonStyle(.bordered)
#endif
                    }
                }
                .padding(.horizontal, Spacing.medium)
                .padding(.bottom, Spacing.small)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
#if os(iOS) || os(macOS)
        .background(.regularMaterial)
#else
        .background(Color(NSColor.controlBackgroundColor))
#endif
        .cornerRadius(12)
        .padding(.horizontal, Spacing.medium)
        .padding(.top, Spacing.small)
    }

    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Spacing.medium) {
                    ForEach(viewModel.session.transcript) { entry in
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
                        .id("summarizing")
                    }

                    // Empty spacer for bottom padding
                    Rectangle()
                        .fill(.clear)
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.vertical)
            }
#if os(iOS)
            .scrollDismissesKeyboard(.interactively)
#endif
            .scrollPosition(id: $scrollID, anchor: .bottom)
            .onChange(of: viewModel.session.transcript.count) { _, _ in
                if let lastEntry = viewModel.session.transcript.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastEntry.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.isSummarizing) { _, isSummarizing in
                if isSummarizing {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo("summarizing", anchor: .bottom)
                    }
                }
            }
        }
        .defaultScrollAnchor(.bottom)
    }

}

struct TranscriptEntryView: View {
    let entry: Transcript.Entry

    var body: some View {
        switch entry {
        case .prompt(let prompt):
            if let text = extractText(from: prompt.segments), !text.isEmpty {
                MessageBubbleView(message: ChatMessage(content: text, isFromUser: true))
                    .id(entry.id)
            }

        case .response(let response):
            if let text = extractText(from: response.segments), !text.isEmpty {
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
            if let text = extractText(from: toolOutput.segments), !text.isEmpty {
                MessageBubbleView(message: ChatMessage(
                    entryID: entry.id,
                    content: "🔧 Tool result: \(text)",
                    isFromUser: false
                ))
                .id(entry.id)
                .animation(.easeInOut(duration: 0.3), value: text)
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

struct FeedbackView: View {
    let viewModel: ChatViewModel
    @Binding var selectedEntry: Transcript.Entry?
    @Binding var isPresented: Bool

    var assistantEntries: [Transcript.Entry] {
        viewModel.session.transcript.filter { entry in
            if case .response = entry {
                return true
            }
            return false
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if assistantEntries.isEmpty {
                    VStack(spacing: Spacing.large) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)

                        Text("No responses to provide feedback on")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: Spacing.medium) {
                            ForEach(assistantEntries) { entry in
                                FeedbackRowView(
                                    entry: entry,
                                    viewModel: viewModel,
                                    isSelected: selectedEntry?.id == entry.id,
                                    onSelect: {
                                        selectedEntry = entry
                                    }
                                )
                            }
                        }
                        .padding()
                    }

                    if let selectedEntry = selectedEntry {
                        VStack(spacing: Spacing.large) {
                            Divider()

                            Text("How was this response?")
                                .font(.headline)

                            HStack(spacing: Spacing.large) {
                                Button(action: {
                                    viewModel.submitFeedback(for: selectedEntry.id, sentiment: .positive)
                                    self.selectedEntry = nil
                                }) {
                                    VStack(spacing: Spacing.small) {
                                        Image(systemName: "hand.thumbsup.fill")
                                            .font(.title)
                                        Text("Good")
                                            .font(.caption)
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)

                                Button(action: {
                                    viewModel.submitFeedback(for: selectedEntry.id, sentiment: .negative)
                                    self.selectedEntry = nil
                                }) {
                                    VStack(spacing: Spacing.small) {
                                        Image(systemName: "hand.thumbsdown.fill")
                                            .font(.title)
                                        Text("Bad")
                                            .font(.caption)
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.red)
                            }
                            .padding(.horizontal)
                            .padding(.bottom)
                        }
                    }
                }
            }
            .navigationTitle("Provide Feedback")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
#if os(macOS)
        .frame(minWidth: 500, idealWidth: 600, maxWidth: .infinity, minHeight: 400, idealHeight: 500, maxHeight: .infinity)
#endif
    }
}

struct FeedbackRowView: View {
    let entry: Transcript.Entry
    let viewModel: ChatViewModel
    let isSelected: Bool
    let onSelect: () -> Void

    var responseText: String {
        guard case .response(let response) = entry else { return "" }

        return response.segments.compactMap { segment in
            if case .text(let textSegment) = segment {
                return textSegment.content
            }
            return nil
        }.joined(separator: " ")
    }

    var existingFeedback: LanguageModelFeedbackAttachment.Sentiment? {
        viewModel.getFeedback(for: entry.id)
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                HStack {
                    Text("Assistant Response")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if let feedback = existingFeedback {
                        HStack(spacing: Spacing.xSmall) {
                            Image(systemName: feedback == .positive ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                                .foregroundStyle(feedback == .positive ? .green : .red)
                            Text(feedback == .positive ? "Good" : "Bad")
                                .font(.caption)
                                .foregroundStyle(feedback == .positive ? .green : .red)
                        }
                    }
                }

                Text(responseText)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .foregroundStyle(.primary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ChatView(viewModel: .constant(ChatViewModel()))
}
