# RAG

Use this reference for retrieval-augmented generation over user documents, app content, notes, transcripts, web pages, or indexed local data.

RAG should keep retrieval, prompt assembly, and UI state separate.

## Data Types

```swift
struct RetrievedChunk: Sendable, Hashable {
    var title: String
    var text: String
    var sourceURL: URL?
}

protocol DocumentRetrieving: Sendable {
    func relevantChunks(for query: String) async throws -> [RetrievedChunk]
}
```

## Grounded Responder

```swift
import FoundationModels

struct RAGResponder {
    var retriever: any DocumentRetrieving

    func respond(to question: String) async throws -> String {
        let chunks = try await retriever.relevantChunks(for: question)
        let context = chunks.map { chunk in
            """
            Source: \(chunk.title)
            \(chunk.text)
            """
        }.joined(separator: "\n\n")

        let session = LanguageModelSession(
            instructions: Instructions("""
            Answer using only the provided context.
            If the context is insufficient, say what is missing.
            Cite source titles when useful.
            """)
        )

        let prompt = """
        Context:
        \(context)

        Question:
        \(question)
        """

        return try await session.respond(to: Prompt(prompt)).content
    }
}
```

## SwiftUI Shape

```swift
@MainActor
@Observable
final class RAGChatViewModel {
    var question = ""
    var answer = ""
    var isLoading = false
    var errorMessage: String?

    private let responder: RAGResponder
    private var task: Task<Void, Never>?

    init(responder: RAGResponder) {
        self.responder = responder
    }

    func ask() {
        task?.cancel()
        let currentQuestion = question

        isLoading = true
        errorMessage = nil

        task = Task {
            do {
                let response = try await responder.respond(to: currentQuestion)
                guard !Task.isCancelled else { return }
                answer = response
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = FoundationModelsErrorPresenter.message(for: error)
            }

            guard !Task.isCancelled else { return }
            isLoading = false
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
        isLoading = false
    }
}
```

## Prompt Rules

- Keep context compact and relevant.
- Include source titles or IDs in the prompt so the model can cite them.
- Tell the model to say when context is insufficient.
- Do not mix retrieved facts with hidden assumptions.
- For private documents, avoid logging full retrieved text.

## Failure States

- No documents indexed.
- No relevant chunks found.
- Retrieval timed out.
- The selected chunks exceed the prompt budget.
- The model refuses or cannot answer from the provided context.
