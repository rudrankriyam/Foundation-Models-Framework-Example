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
    @State private var showInstructionsSheet = false
    @State private var showFeedbackSheet = false
    @State private var showVoiceSheet = false
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            messagesView
                .contentShape(Rectangle())
                .onTapGesture {
                    isTextFieldFocused = false
                }

            ChatInputView(
                messageText: $messageText,
                isTextFieldFocused: $isTextFieldFocused,
                showVoiceSheet: $showVoiceSheet
            )
        }
        .environment(viewModel)
        .navigationTitle("Chat (\(viewModel.session.transcript.estimatedTokenCount) tokens)")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { showInstructionsSheet = true }, label: {
                    Label("Instructions", systemImage: "doc.text")
                })
                .help("Customize AI behavior")

                Button(action: { showFeedbackSheet = true }, label: {
                    Label("Feedback", systemImage: "bubble.left.and.exclamationmark.bubble.right")
                })
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
                isPresented: $showFeedbackSheet
            )
#if os(macOS)
            .frame(minWidth: 600, minHeight: 400)
#endif
        }
        .sheet(isPresented: $showInstructionsSheet) {
            ChatInstructionsView(
                instructions: $viewModel.instructions,
                samplingStrategy: $viewModel.samplingStrategy,
                topKSamplingValue: $viewModel.topKSamplingValue,
                useFixedSeed: $viewModel.useFixedSeed,
                onApply: {
                    viewModel.updateInstructions(viewModel.instructions)
                    viewModel.clearChat()
                }
            )
#if os(macOS)
            .frame(minWidth: 500, minHeight: 400)
#endif
        }
        .sheet(isPresented: $showVoiceSheet) {
            VoiceView()
#if os(macOS)
            .frame(minWidth: 700, minHeight: 500)
#endif
        }
    }

    // MARK: - View Components

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

                    if viewModel.isApplyingWindow {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Optimizing conversation history...")
                                .font(.caption)
                                .foregroundStyle(.blue)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .id("windowing")
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
            .onChange(of: viewModel.isApplyingWindow) { _, isApplyingWindow in
                if isApplyingWindow {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo("windowing", anchor: .bottom)
                    }
                }
            }
        }
        .defaultScrollAnchor(.bottom)
    }
}

struct ChatViewContainer: View {
    @State private var viewModel = ChatViewModel()

    var body: some View {
        ChatView(viewModel: $viewModel)
    }
}

#Preview {
    NavigationStack {
        ChatView(viewModel: .constant(ChatViewModel()))
    }
}
