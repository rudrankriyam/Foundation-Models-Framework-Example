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
            ToolbarItem(placement: .primaryAction) {
                Button("Clear") {
                    viewModel.clearChat()
                }
                .disabled(viewModel.session.transcript.isEmpty)
            }
        }
        .onAppear {
            // Auto-focus when chat appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
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
                        .frame(minHeight: 80, maxHeight: 150)
                    
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
        .animation(.easeInOut(duration: 0.2), value: showInstructions)
    }

    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
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
    ChatView(viewModel: .constant(ChatViewModel()))
}
