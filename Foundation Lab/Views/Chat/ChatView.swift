//
//  ChatView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/9/25.
//

import SwiftUI
import FoundationModels

struct ChatView: View {
    @State private var viewModel = ChatViewModel()
    @State private var scrollID: String?
    @State private var messageText = ""
    @State private var showInstructionsSheet = false
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            messagesView
                .contentShape(Rectangle())
                .onTapGesture {
                    isTextFieldFocused = false
                }

            ChatInputView(
                messageText: $messageText,
                chatViewModel: viewModel,
                isTextFieldFocused: $isTextFieldFocused
            )
        }
        .environment(viewModel)
        .navigationTitle(viewModel.voiceState.isActive ? "Voice" : "Chat")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }

            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { showInstructionsSheet = true }, label: {
                    Label("Instructions", systemImage: "doc.text")
                })
                .help("Customize AI behavior")

                Button(action: clearChat, label: { Image(systemName: "xmark") })
                .disabled(isChatEffectivelyEmpty)
                .help("Clear chat")
            }
        }
        .alert(
            "Error",
            isPresented: $viewModel.showError,
            actions: { Button("OK") { viewModel.dismissError() } },
            message: { Text(viewModel.errorMessage ?? "An unknown error occurred") }
        )
        .onAppear {
            // Auto-focus when chat appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
        .onDisappear {
            viewModel.tearDown()
        }
#if os(iOS)
        .fullScreenCover(isPresented: $showInstructionsSheet) {
            NavigationStack {
                ChatInstructionsView(
                    viewModel: $viewModel,
                    onApply: {
                        viewModel.updateInstructions(viewModel.instructions)
                        clearChat()
                    }
                )
                .navigationTitle("Instructions")
            }
        }
#else
        .sheet(isPresented: $showInstructionsSheet) {
            NavigationStack {
                ChatInstructionsView(
                    viewModel: $viewModel,
                    onApply: {
                        viewModel.updateInstructions(viewModel.instructions)
                        clearChat()
                    }
                )
                .navigationTitle("Instructions")
                .frame(minWidth: 500, minHeight: 400)
            }
        }
#endif
    }

    // MARK: - View Components

    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Spacing.medium) {
                    if isChatEffectivelyEmpty {
                        Text("How can we help you today?")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 48)
                    }

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

    private var isChatEffectivelyEmpty: Bool {
        !viewModel.session.transcript.contains { entry in
            switch entry {
            case .instructions:
                return false
            default:
                return true
            }
        }
    }

    private func clearChat() {
        messageText = ""
        scrollID = "bottom"
        viewModel.clearChat()
    }
}

#Preview {
    NavigationStack {
        ChatView()
    }
}
