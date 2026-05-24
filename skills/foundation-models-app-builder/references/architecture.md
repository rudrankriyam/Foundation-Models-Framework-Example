# Architecture Recipes

Use these patterns when a Foundation Models feature should be reusable across SwiftUI, App Intents, CLI commands, widgets, or tests.

## Shared Text Capability

```swift
import Foundation
import FoundationModels

public struct TextGenerationRequest: Sendable, Hashable {
    public var prompt: String
    public var systemPrompt: String?
    public var options: GenerationOptions?

    public init(prompt: String, systemPrompt: String? = nil, options: GenerationOptions? = nil) {
        self.prompt = prompt
        self.systemPrompt = systemPrompt
        self.options = options
    }
}

public struct TextGenerationResult: Sendable, Hashable {
    public var content: String
    public var estimatedTokenCount: Int?
}

public protocol TextGenerating: Sendable {
    func generateText(for request: TextGenerationRequest) async throws -> TextGenerationResult
}

public struct FoundationModelsTextGenerator: TextGenerating {
    public init() {}

    public func generateText(for request: TextGenerationRequest) async throws -> TextGenerationResult {
        let prompt = request.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else {
            throw AppAIError.invalidPrompt
        }

        let model = SystemLanguageModel.default
        let session: LanguageModelSession

        if let systemPrompt = request.systemPrompt?.trimmingCharacters(in: .whitespacesAndNewlines),
           !systemPrompt.isEmpty {
            session = LanguageModelSession(
                model: model,
                instructions: Instructions(systemPrompt)
            )
        } else {
            session = LanguageModelSession(model: model)
        }

        let content: String
        if let options = request.options {
            content = try await session.respond(to: Prompt(prompt), options: options).content
        } else {
            content = try await session.respond(to: Prompt(prompt)).content
        }

        return TextGenerationResult(
            content: content,
            estimatedTokenCount: session.transcript.estimatedTokenCount
        )
    }
}
```

## Use Case Wrapper

```swift
public struct GenerateSummaryUseCase: Sendable {
    private let generator: any TextGenerating

    public init(generator: any TextGenerating = FoundationModelsTextGenerator()) {
        self.generator = generator
    }

    public func execute(notes: String) async throws -> TextGenerationResult {
        try await generator.generateText(
            for: TextGenerationRequest(
                prompt: notes,
                systemPrompt: "Summarize the notes into three concise bullets.",
                options: GenerationOptions(temperature: 0.2, maximumResponseTokens: 180)
            )
        )
    }
}
```

## SwiftUI Adapter

```swift
import Observation
import SwiftUI

@MainActor
@Observable
final class SummaryViewModel {
    var input = ""
    var output = ""
    var isGenerating = false
    var errorMessage: String?

    private let useCase: GenerateSummaryUseCase
    private var task: Task<Void, Never>?

    init(useCase: GenerateSummaryUseCase = GenerateSummaryUseCase()) {
        self.useCase = useCase
    }

    func generate() {
        task?.cancel()
        isGenerating = true
        errorMessage = nil

        task = Task {
            do {
                let result = try await useCase.execute(notes: input)
                guard !Task.isCancelled else { return }
                output = result.content
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = AppAIError.userMessage(for: error)
            }

            isGenerating = false
        }
    }

    func cancel() {
        task?.cancel()
        isGenerating = false
    }
}
```

## App Intent Adapter

```swift
import AppIntents

struct SummarizeNotesIntent: AppIntent {
    static let title: LocalizedStringResource = "Summarize Notes"

    @Parameter(title: "Notes")
    var notes: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let result = try await GenerateSummaryUseCase().execute(notes: notes)
        return .result(value: result.content)
    }
}
```

## Shared Error Mapping

```swift
enum AppAIError: Error, LocalizedError {
    case invalidPrompt
    case modelUnavailable(String)

    var errorDescription: String? {
        switch self {
        case .invalidPrompt:
            "Enter a prompt before generating."
        case .modelUnavailable(let reason):
            "Apple Intelligence is not available: \(reason)"
        }
    }

    static func userMessage(for error: Error) -> String {
        switch error {
        case LanguageModelSession.GenerationError.exceededContextWindowSize:
            "This conversation is too long. Start a new chat or remove earlier messages."
        case LanguageModelSession.GenerationError.guardrailViolation:
            "The request was blocked by the safety system."
        case LanguageModelSession.GenerationError.assetsUnavailable:
            "Foundation Models are temporarily unavailable."
        case LanguageModelSession.GenerationError.concurrentRequests:
            "Wait for the current response to finish."
        case LanguageModelSession.GenerationError.rateLimited:
            "Too many requests. Try again in a moment."
        case LanguageModelSession.GenerationError.unsupportedLanguageOrLocale:
            "This language or locale is not supported."
        case LanguageModelSession.GenerationError.decodingFailure:
            "The response could not be decoded. Try simplifying the request."
        case LanguageModelSession.GenerationError.unsupportedGuide:
            "One of the generation guides is not supported."
        case LanguageModelSession.GenerationError.refusal(_, _):
            "The model declined to respond."
        default:
            error.localizedDescription
        }
    }
}
```

## Token Estimate Helper

Use real token counting when available in the deployment target; otherwise keep a conservative fallback.

```swift
import FoundationModels

extension Transcript {
    var estimatedTokenCount: Int {
        reduce(0) { partial, entry in
            partial + String(describing: entry).count / 4 + 1
        }
    }
}
```
