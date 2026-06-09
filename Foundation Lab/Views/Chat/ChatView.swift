//
//  ChatView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/9/25.
//

import SwiftUI
import FoundationLabCore
import FoundationModels

struct ChatView: View {
    let title: String
    let showsDoneButton: Bool
    let tearsDownOnDisappear: Bool

    @State private var viewModel = ChatViewModel()
    @State private var scrollID: String?
    @State private var messageText = ""
    @State private var showInstructionsSheet = false
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss

    init(title: String = "Chat", showsDoneButton: Bool = true, tearsDownOnDisappear: Bool = true) {
        self.title = title
        self.showsDoneButton = showsDoneButton
        self.tearsDownOnDisappear = tearsDownOnDisappear
    }

    var body: some View {
        VStack(spacing: 0) {
            TokenUsageBar(
                currentTokenCount: viewModel.currentTokenCount,
                maxContextSize: viewModel.maxContextSize,
                tokenUsageFraction: viewModel.tokenUsageFraction
            )

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
        .navigationTitle(viewModel.voiceState.isActive ? "Voice" : title)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                modelRuntimeMenu
            }

            ToolbarItem(placement: .cancellationAction) {
                reasoningMenu
            }

            if showsDoneButton {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                }
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
            if tearsDownOnDisappear {
                viewModel.tearDown()
            }
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

                    ForEach(transcriptDisplayEntries, id: \.id) { displayEntry in
                        TranscriptEntryView(entry: displayEntry.entry)
                            .id(displayEntry.id)
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
                if let lastEntryID = transcriptDisplayEntries.last?.id {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastEntryID, anchor: .bottom)
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

    private var modelRuntimeMenu: some View {
        Menu {
            ForEach(FoundationLabModelRuntime.allCases, id: \.self) { runtime in
                Button {
                    viewModel.selectModelRuntime(runtime)
                    clearInputAfterRuntimeChange()
                } label: {
                    Label(runtime.displayName, systemImage: runtime.systemImage)
                }
                .disabled(runtime == .privateCloudCompute && !viewModel.canSelectPrivateCloudCompute)
            }

            Divider()

            Text(viewModel.modelRuntimeStatus)
        } label: {
            Label(viewModel.selectedModelRuntime.shortName, systemImage: viewModel.selectedModelRuntime.systemImage)
        }
        .help(viewModel.modelRuntimeStatus)
    }

    private var transcriptDisplayEntries: [(id: String, entry: Transcript.Entry)] {
        viewModel.session.transcript.enumerated().map { index, entry in
            ("\(index)-\(entry.id)", entry)
        }
    }

    private var reasoningMenu: some View {
        Menu {
            ForEach(FoundationLabReasoningLevel.allCases, id: \.self) { level in
                Button {
                    viewModel.selectReasoningLevel(level)
                    clearInputAfterRuntimeChange()
                } label: {
                    Label(level.displayName, systemImage: level.systemImage)
                }
                .disabled(level != .none && !viewModel.canUseReasoning)
            }

            Divider()

            Toggle("Show Reasoning Trace", isOn: .init(
                get: { viewModel.showsReasoningTrace },
                set: { viewModel.showsReasoningTrace = $0 }
            ))
        } label: {
            Label(viewModel.selectedReasoningLevel.displayName, systemImage: viewModel.selectedReasoningLevel.systemImage)
        }
        .disabled(viewModel.selectedModelRuntime == .onDevice)
        .help("Reasoning levels require PCC on Xcode 27.")
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

    private func clearInputAfterRuntimeChange() {
        messageText = ""
        scrollID = "bottom"
    }
}

#Preview {
    NavigationStack {
        ChatView()
    }
}
