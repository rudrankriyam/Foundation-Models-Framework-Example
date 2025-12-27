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

@MainActor
@Observable
final class RAGChatViewModel {
    var conversation: [RAGChatEntry] = []
    var isSearching = false
    var isGenerating = false
    var showDocumentPicker = false
    var indexedDocumentCount = 0
    var errorMessage: String?
    var showError = false

    // LumoKit instance
    private var lumoKit: LumoKit?
    private var isInitialized = false

    // Configuration
    private var vecturaConfig: VecturaConfig?
    private var chunkingConfig: ChunkingConfig?

    init() {
        do {
            let searchOptions = VecturaConfig.SearchOptions(
                defaultNumResults: 5,
                minThreshold: 0.5
            )
            vecturaConfig = try VecturaConfig(
                name: "foundation-lab-rag",
                searchOptions: searchOptions
            )

            chunkingConfig = try ChunkingConfig(
                chunkSize: 500,
                overlapPercentage: 0.15,
                strategy: .semantic,
                contentType: .prose
            )
        } catch {
            errorMessage = "Failed to initialize RAG configuration: \(error.localizedDescription)"
            showError = true
        }
    }

    func initialize() async {
        guard !isInitialized else { return }

        guard let config = vecturaConfig, let chunking = chunkingConfig else {
            errorMessage = "RAG configuration not initialized"
            showError = true
            return
        }

        do {
            lumoKit = try await LumoKit(
                config: config,
                chunkingConfig: chunking
            )
            isInitialized = true
        } catch {
            errorMessage = "Failed to initialize RAG: \(error.localizedDescription)"
            showError = true
        }
    }

    func indexDocument(from url: URL) async {
        await initialize()

        guard let lumoKit = lumoKit,
              let chunking = chunkingConfig else {
            errorMessage = "RAG system not initialized"
            showError = true
            return
        }

        isSearching = true

        // Start accessing security-scoped resource
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            try await lumoKit.parseAndIndex(url: url, chunkingConfig: chunking)
            indexedDocumentCount += 1
        } catch LumoKitError.fileNotFound {
            errorMessage = "File not found at specified URL"
            showError = true
        } catch LumoKitError.unsupportedFileType {
            errorMessage = "Unsupported file type. Please use PDF, Markdown, or Text files."
            showError = true
        } catch {
            errorMessage = "Failed to index document: \(error.localizedDescription)"
            showError = true
        }

        isSearching = false
    }

    func indexText(_ text: String, title: String) async {
        await initialize()

        guard let lumoKit = lumoKit,
              let chunking = chunkingConfig else {
            errorMessage = "RAG system not initialized"
            showError = true
            return
        }

        isSearching = true

        do {
            let chunks = try lumoKit.chunkText(text, config: chunking)
            let texts = chunks.map { $0.text }
            try await lumoKit.addDocuments(texts: texts)
            indexedDocumentCount += 1
        } catch {
            errorMessage = "Failed to index text: \(error.localizedDescription)"
            showError = true
        }

        isSearching = false
    }

    func resetDatabase() async {
        guard let lumoKit = lumoKit else { return }

        do {
            try await lumoKit.resetDB()
            indexedDocumentCount = 0
        } catch {
            errorMessage = "Failed to reset database: \(error.localizedDescription)"
            showError = true
        }
    }

    func loadSampleDocuments() async {
        await initialize()

        guard let lumoKit = lumoKit,
              let chunking = chunkingConfig else { return }

        isSearching = true

        let sampleTexts = [
            ("Swift Concurrency", """
            Swift's concurrency model provides a safe and efficient way to write concurrent code. \
            Key concepts include async/await, actors, and structured concurrency. \
            The @MainActor attribute ensures code runs on the main thread. \
            Task groups allow parallel execution of child tasks. \
            Sendable protocol ensures data can be safely transferred between concurrent contexts.
            """),
            ("Foundation Models", """
            The Foundation Models framework enables AI-powered features in iOS apps. \
            SystemLanguageModel provides access to on-device language models. \
            LanguageModelSession manages conversation context and history. \
            Structured generation allows parsing responses into custom types. \
            Streaming responses enable real-time output display.
            """),
            ("HealthKit", """
            HealthKit provides a central repository for health and fitness data. \
            HKObserverQuery monitors changes to health data in real-time. \
            Background delivery enables efficient data synchronization. \
            Sample types include workouts, heart rate, and sleep analysis. \
            Authorization requires user permission for each data type.
            """)
        ]

        do {
            for (_, text) in sampleTexts {
                let chunks = try lumoKit.chunkText(text, config: chunking)
                let texts = chunks.map { $0.text }
                try await lumoKit.addDocuments(texts: texts)
            }
            indexedDocumentCount += sampleTexts.count
        } catch {
            errorMessage = "Failed to load samples: \(error.localizedDescription)"
            showError = true
        }

        isSearching = false
    }

    func sendMessage(_ content: String) async {
        await initialize()

        // Add user message
        let userEntry = RAGChatEntry(role: .user, content: content, sources: [])
        conversation.append(userEntry)

        isSearching = true

        // Search for relevant documents
        var relevantChunks: [RAGChunk] = []

        do {
            if let lumoKit = lumoKit {
                let results = try await lumoKit.semanticSearch(
                    query: content,
                    numResults: 5,
                    threshold: 0.5
                )

                relevantChunks = results.map { result in
                    RAGChunk(
                        documentId: result.id.uuidString,
                        documentTitle: "Source",
                        content: result.text,
                        chunkIndex: 0,
                        similarityScore: Double(result.score)
                    )
                }
            }
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
            showError = true
        }

        isSearching = false
        isGenerating = true

        // Create assistant entry with empty content for streaming
        let assistantEntry = RAGChatEntry(role: .assistant, content: "", sources: relevantChunks)
        conversation.append(assistantEntry)

        // Generate response using Foundation Models
        let systemPrompt = """
        You are a helpful assistant. Answer the user's question based on the provided \
        context from documents. If the context doesn't contain relevant information, \
        say so clearly. Cite specific content from the documents when possible.
        """

        let contextText = relevantChunks.isEmpty ?
            "No relevant documents found." :
            relevantChunks.enumerated().map { index, chunk in
                "[Document \(index + 1)]: \(chunk.content)"
            }.joined(separator: "\n\n")

        let augmentedPrompt = """
        \(systemPrompt)

        CONTEXT:
        \(contextText)
        """

        do {
            let session = LanguageModelSession(
                model: SystemLanguageModel(useCase: .general),
                instructions: Instructions(augmentedPrompt)
            )

            let responseStream = session.streamResponse(to: Prompt(content))

            for try await snapshot in responseStream {
                assistantEntry.content = snapshot.content
            }
        } catch {
            if assistantEntry.content.isEmpty {
                assistantEntry.content = "Failed to generate response: \(error.localizedDescription)"
            }
        }

        isGenerating = false
    }

    func dismissError() {
        showError = false
        errorMessage = nil
    }
}
