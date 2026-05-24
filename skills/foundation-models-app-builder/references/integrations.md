# Integration Recipes

Use these recipes for tool calling, RAG, voice, HealthKit, App Intents, permissions, and multilingual app features.

## Tool Calling

```swift
import Foundation
import FoundationModels

struct CalculatorTool: Tool {
    let name = "calculate"
    let description = "Perform basic arithmetic."

    @Generable
    struct Arguments: Sendable {
        let firstNumber: Double
        let operation: Operation
        let secondNumber: Double
    }

    @Generable
    enum Operation: String, Sendable {
        case add
        case subtract
        case multiply
        case divide
    }

    @Generable
    struct CalculationResult: Sendable {
        let expression: String
        let result: Double
    }

    func call(arguments: Arguments) async throws -> CalculationResult {
        let result = switch arguments.operation {
        case .add:
            arguments.firstNumber + arguments.secondNumber
        case .subtract:
            arguments.firstNumber - arguments.secondNumber
        case .multiply:
            arguments.firstNumber * arguments.secondNumber
        case .divide:
            arguments.firstNumber / arguments.secondNumber
        }

        return CalculationResult(
            expression: "\(arguments.firstNumber) \(arguments.operation.rawValue) \(arguments.secondNumber)",
            result: result
        )
    }
}

let session = LanguageModelSession(
    tools: [CalculatorTool()],
    instructions: "Use the calculator tool for arithmetic. Explain the result briefly."
)

let response = try await session.respond(
    to: Prompt("What is 19.5 multiplied by 4.2?")
)
```

For tools that write data, require confirmation in the UI before committing changes. Examples: creating reminders, calendar events, health notes, messages, or files.

## Tool Error Output

Prefer a structured failure result when the model can recover, and throw only when the app should stop the tool call.

```swift
@Generable
struct ToolResult: Sendable {
    let success: Bool
    let message: String
    let value: String?
}
```

## RAG Skeleton

```swift
struct RetrievedChunk: Sendable, Hashable {
    var title: String
    var text: String
}

protocol DocumentRetrieving: Sendable {
    func relevantChunks(for query: String) async throws -> [RetrievedChunk]
}

struct RAGResponder {
    var retriever: any DocumentRetrieving

    func respond(to question: String) async throws -> String {
        let chunks = try await retriever.relevantChunks(for: question)
        let context = chunks.map { "Source: \($0.title)\n\($0.text)" }.joined(separator: "\n\n")

        let session = LanguageModelSession(
            instructions: Instructions("""
            Answer using only the provided context.
            If the context is insufficient, say what is missing.
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

## Voice State Machine Shape

```swift
enum VoiceInteractionState: Equatable {
    case idle
    case requestingPermission
    case listening
    case transcribing
    case generating
    case speaking
    case failed(String)
}

@MainActor
@Observable
final class VoiceAssistantViewModel {
    var state: VoiceInteractionState = .idle
    var transcript = ""
    var response = ""

    func handleFinalTranscript(_ text: String) {
        transcript = text
        state = .generating

        Task {
            do {
                response = try await LanguageModelSession().respond(to: Prompt(text)).content
                state = .speaking
                // Send response to AVSpeechSynthesizer or Speech framework wrapper here.
            } catch {
                state = .failed(AppAIError.userMessage(for: error))
            }
        }
    }
}
```

Keep speech recognition, model inference, and speech synthesis as separate services. This makes cancellation, permissions, and tests much easier.

## HealthKit Safety

```swift
let healthInstructions = Instructions("""
You are a wellness assistant.
Summarize trends and encourage healthy habits.
Do not diagnose, prescribe, or claim medical certainty.
Tell the user to consult a qualified professional for medical concerns.
""")
```

For HealthKit-backed features:

- request HealthKit authorization before model generation
- pass only the minimum relevant metrics to the prompt
- avoid diagnosis and treatment language
- provide source/date ranges for metrics
- handle missing or denied data as a normal UI state

## App Intent Over Shared Capability

```swift
import AppIntents

struct GenerateLocalizedResponseIntent: AppIntent {
    static let title: LocalizedStringResource = "Generate Localized Response"

    @Parameter(title: "Prompt")
    var prompt: String

    @Parameter(title: "Language")
    var language: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let session = LanguageModelSession(
            instructions: Instructions("Respond in \(language).")
        )
        let response = try await session.respond(to: Prompt(prompt))
        return .result(value: response.content)
    }
}
```

When the same task appears in both the app and App Intents, move the model call into a shared use case and let the intent call that use case.

## Permission Boundary Checklist

- Contacts: explain why search is needed; avoid dumping full contact details into prompts.
- Calendar: preview event creation before saving.
- Reminders: preview title, due date, priority, and notes before saving.
- Location: request foreground location only when the feature needs it.
- Music: handle no subscription or denied media access.
- Speech and microphone: show listening state, cancellation, and retry controls.
- HealthKit: show selected metric types and date range clearly.
