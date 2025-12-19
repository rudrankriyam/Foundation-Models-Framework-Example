//
//  RAGChatView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 12/19/25.
//

import SwiftUI
import FoundationModels
import LumoKit
import VecturaKit

struct RAGChatView: View {
    @State private var viewModel = RAGChatViewModel()
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            messagesView
                .contentShape(Rectangle())
                .onTapGesture {
                    isTextFieldFocused = false
                }

            // Input
            chatInputView
        }
        .navigationTitle("RAG Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { viewModel.showDocumentPicker = true }) {
                    Label("Documents", systemImage: "doc.text")
                }
            }
        }
        .sheet(isPresented: $viewModel.showDocumentPicker) {
            RAGDocumentPickerView(viewModel: viewModel)
        }
    }

    private var messagesView: some View {
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

                if viewModel.isGenerating {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Generating...")
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
                    .foregroundStyle(messageText.isEmpty ? .gray : .blue)
            }
            .disabled(messageText.isEmpty || viewModel.isGenerating)
        }
        .padding()
    }

    private func sendMessage() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        messageText = ""
        Task {
            await viewModel.sendMessage(trimmed)
        }
    }
}

// MARK: - RAG Chat View Model

@Observable
final class RAGChatViewModel {
    var conversation: [RAGChatEntry] = []
    var isSearching = false
    var isGenerating = false
    var showDocumentPicker = false
    var errorMessage: String?

    // LumoKit instance
    private var lumoKit: LumoKit?
    private var isInitialized = false

    func initialize() async {
        guard !isInitialized else { return }

        do {
            let vecturaConfig = try VecturaConfig(
                name: "foundation-lab-rag",
                searchOptions: .init(defaultNumResults: 5, minThreshold: 0.5)
            )

            let chunkingConfig = try ChunkingConfig(
                chunkSize: 500,
                overlapPercentage: 0.15,
                strategy: .semantic,
                contentType: .prose
            )

            lumoKit = try await LumoKit(
                config: vecturaConfig,
                chunkingConfig: chunkingConfig
            )
            isInitialized = true
        } catch {
            errorMessage = "Failed to initialize RAG: \(error.localizedDescription)"
        }
    }

    func loadSampleDocuments() {
        // Sample document loading - to be implemented with LumoKit API
    }

    func sendMessage(_ content: String) async {
        await initialize()

        // Add user message
        let userEntry = RAGChatEntry(role: .user, content: content, sources: [])
        conversation.append(userEntry)

        isGenerating = true

        // Generate response using LumoKit's semantic search
        var responseContent = "RAG functionality will be demonstrated once documents are indexed."
        var relevantSources: [RAGChunk] = []

        do {
            if let lumoKit = lumoKit {
                let results = try await lumoKit.semanticSearch(
                    query: content,
                    numResults: 5,
                    threshold: 0.5
                )

                // Process search results
                relevantSources = results.map { result in
                    RAGChunk(
                        documentId: result.id.uuidString,
                        documentTitle: result.id.uuidString,
                        content: result.id.uuidString,
                        chunkIndex: 0,
                        similarityScore: Double(result.score)
                    )
                }

                if !results.isEmpty {
                    responseContent = "Found \(results.count) relevant document chunks for your query about '\(content)'."
                }
            }
        } catch {
            responseContent = "Search failed: \(error.localizedDescription)"
        }

        isGenerating = false

        let assistantEntry = RAGChatEntry(
            role: .assistant,
            content: responseContent,
            sources: relevantSources
        )
        conversation.append(assistantEntry)
    }
}

// MARK: - Supporting Types

struct RAGChatEntry: Identifiable {
    let id = UUID()
    let role: Role
    let content: String
    let sources: [RAGChunk]

    enum Role {
        case user
        case assistant
    }
}

struct RAGChunk {
    let documentId: String
    let documentTitle: String
    let content: String
    let chunkIndex: Int
    let similarityScore: Double
}

// MARK: - Message Bubble

struct RAGMessageBubble: View {
    let entry: RAGChatEntry

    var body: some View {
        HStack {
            if entry.role == .user { Spacer(minLength: 60) }

            VStack(alignment: entry.role == .user ? .trailing : .leading, spacing: 6) {
                Text(entry.content)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(entry.role == .user ? Color.accentColor : Color.gray.opacity(0.15))
                    .foregroundStyle(entry.role == .user ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                if entry.role == .assistant && !entry.sources.isEmpty {
                    sourcesView
                }
            }

            if entry.role == .assistant { Spacer(minLength: 60) }
        }
        .padding(.horizontal, Spacing.medium)
    }

    private var sourcesView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.small) {
                ForEach(Array(entry.sources.enumerated()), id: \.offset) { index, source in
                    HStack(spacing: 4) {
                        Text("\(index + 1)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(width: 16, height: 16)
                            .background(Color.blue)
                            .clipShape(Circle())

                        Text(source.documentTitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}
