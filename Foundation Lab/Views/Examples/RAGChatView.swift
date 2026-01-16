//
//  RAGChatView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 12/19/25.
//

import SwiftUI
import FoundationModels

struct RAGChatView: View {
    @State private var viewModel = RAGChatViewModel()
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var scrollID: String?

    var body: some View {
        VStack(spacing: 0) {
            messagesView
                .contentShape(Rectangle())
                .onTapGesture {
                    isTextFieldFocused = false
                }

            chatInputView
        }
        .navigationTitle("RAG Chat")
        .onAppear {
            Task {
                await viewModel.loadFromDatabase()
            }
        }
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.showDocumentPicker = true
                } label: {
                    Label("Documents", systemImage: "doc.text")
                }
            }
        }
        .sheet(isPresented: $viewModel.showDocumentPicker) {
            RAGDocumentPickerView(viewModel: viewModel)
        }
        .alert(
            "Error",
            isPresented: $viewModel.showError,
            actions: { Button("OK") { viewModel.dismissError() } },
            message: { Text(viewModel.errorMessage ?? "An unknown error occurred") }
        )
    }

    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Spacing.medium) {
                    if viewModel.conversation.isEmpty {
                        ContentUnavailableView(
                            "RAG Chat",
                            systemImage: "doc.text.magnifyingglass",
                            description: Text("Ask questions about your indexed documents")
                        )
                        .padding(.top, 100)
                    }

                    ForEach(viewModel.conversation) { entry in
                        RAGMessageBubble(entry: entry)
                    }

                    if viewModel.isSearching || viewModel.isGenerating {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text(viewModel.isSearching ? "Searching..." : "Generating...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                    }

                    Rectangle()
                        .fill(.clear)
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.vertical)
            }
            .defaultScrollAnchor(.bottom)
            .scrollPosition(id: $scrollID, anchor: .bottom)
            .onChange(of: viewModel.conversation.count) { _, _ in
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onChange(of: viewModel.isGenerating) { _, isGenerating in
                if isGenerating {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
        }
    }

    private var chatInputView: some View {
        HStack(spacing: Spacing.medium) {
            TextField("Ask about your documents...", text: $messageText, axis: .vertical)
                .textFieldStyle(.plain)
                .focused($isTextFieldFocused)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .onSubmit {
                    sendMessage()
                }

            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(trimmedMessage.isEmpty ? .gray : .blue)
            }
            .disabled(trimmedMessage.isEmpty || viewModel.isSearching || viewModel.isGenerating)
        }
        .padding()
    }

    private func sendMessage() {
        let trimmed = trimmedMessage
        guard !trimmed.isEmpty else { return }

        messageText = ""
        Task {
            await viewModel.sendMessage(trimmed)
        }
    }

    private var trimmedMessage: String {
        messageText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
