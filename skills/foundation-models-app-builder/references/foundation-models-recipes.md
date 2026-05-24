# Foundation Models Recipes

Use these recipes for sessions, availability, streaming, generation options, errors, and multilingual basics.

## Availability Gate

```swift
import FoundationModels

struct ModelAvailabilityStatus: Sendable, Hashable {
    var isAvailable: Bool
    var reason: String?
}

func currentFoundationModelsAvailability() -> ModelAvailabilityStatus {
    switch SystemLanguageModel.default.availability {
    case .available:
        ModelAvailabilityStatus(isAvailable: true)
    case .unavailable(let reason):
        let message = switch reason {
        case .deviceNotEligible:
            "This device does not support Apple Intelligence."
        case .appleIntelligenceNotEnabled:
            "Apple Intelligence is not enabled."
        case .modelNotReady:
            "The model is still downloading or preparing."
        @unknown default:
            "Foundation Models are unavailable."
        }

        return ModelAvailabilityStatus(isAvailable: false, reason: message)
    }
}
```

## One-Shot Response

```swift
import FoundationModels

func generateTitle(for topic: String) async throws -> String {
    let session = LanguageModelSession()
    let response = try await session.respond(
        to: Prompt("Generate a short, specific title for: \(topic)")
    )
    return response.content
}
```

## Instructions

```swift
let instructions = Instructions("""
You are a concise writing assistant.
Prefer concrete language.
Never invent facts that are not in the prompt.
""")

let session = LanguageModelSession(instructions: instructions)
let response = try await session.respond(
    to: Prompt("Rewrite this release note for developers: \(draft)")
)
```

## Generation Options

```swift
let deterministic = GenerationOptions(
    sampling: .greedy,
    temperature: 0.1,
    maximumResponseTokens: 160
)

let creative = GenerationOptions(
    sampling: .random(probabilityThreshold: 0.9),
    temperature: 0.8,
    maximumResponseTokens: 400
)

let response = try await LanguageModelSession().respond(
    to: Prompt("Suggest three feature names for an on-device AI app."),
    options: creative
)
```

Use low temperature for extraction, classification, summaries, and app logic. Use higher temperature for brainstorming and creative writing.

## Streaming Text

```swift
import FoundationModels
import Observation

@MainActor
@Observable
final class StreamingTextViewModel {
    var output = ""
    var isStreaming = false
    var errorMessage: String?

    private var task: Task<Void, Never>?

    func start(prompt: String) {
        task?.cancel()
        output = ""
        isStreaming = true
        errorMessage = nil

        task = Task {
            do {
                let session = LanguageModelSession()
                let stream = session.streamResponse(to: Prompt(prompt))

                for try await partial in stream {
                    guard !Task.isCancelled else { return }
                    output = partial.content
                }
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = AppAIError.userMessage(for: error)
            }

            isStreaming = false
        }
    }

    func cancel() {
        task?.cancel()
        isStreaming = false
    }
}
```

Foundation Models streaming snapshots represent the current response state. Assign the latest snapshot content rather than appending blindly unless the API surface returns deltas in your target SDK.

## Multi-Turn Session

```swift
let session = LanguageModelSession(
    instructions: "Remember user preferences during this conversation."
)

let first = try await session.respond(to: "I am planning a trip to Japan.")
let second = try await session.respond(to: "What should I pack?")

print(first.content)
print(second.content)
```

Use a persistent session only when conversation memory is part of the feature. Use fresh sessions for unrelated commands to avoid accidental context bleed.

## Prewarming

```swift
let session = LanguageModelSession(
    instructions: "You generate short workout suggestions."
)

session.prewarm(promptPrefix: "Suggest a 20-minute workout for")

let response = try await session.respond(
    to: "Suggest a 20-minute workout for a beginner with no equipment."
)
```

Prewarm when the user is likely to submit soon and the prompt prefix is stable. Do not prewarm for every possible route in an app.

## Error Handling

```swift
func friendlyMessage(for error: Error) -> String {
    switch error {
    case LanguageModelSession.GenerationError.exceededContextWindowSize:
        "The conversation is too long. Start a new chat or summarize earlier messages."
    case LanguageModelSession.GenerationError.guardrailViolation:
        "The request was blocked by safety guardrails."
    case LanguageModelSession.GenerationError.assetsUnavailable:
        "Foundation Models are temporarily unavailable."
    case LanguageModelSession.GenerationError.concurrentRequests:
        "Wait for the current response to finish."
    case LanguageModelSession.GenerationError.rateLimited:
        "Too many requests. Try again shortly."
    case LanguageModelSession.GenerationError.unsupportedLanguageOrLocale:
        "This language is not supported by Foundation Models."
    case LanguageModelSession.GenerationError.decodingFailure:
        "The response could not be decoded. Try a simpler prompt."
    case LanguageModelSession.GenerationError.unsupportedGuide:
        "A generation guide is unsupported."
    case LanguageModelSession.GenerationError.refusal(_, _):
        "The model declined to respond."
    default:
        error.localizedDescription
    }
}
```

## Multilingual Session Choice

```swift
func respondInFreshSession(prompt: String, languageName: String) async throws -> String {
    let session = LanguageModelSession(
        instructions: Instructions("Respond in \(languageName). Keep the answer concise.")
    )

    return try await session.respond(to: Prompt(prompt)).content
}
```

Use fresh sessions when switching languages for independent tasks. Use one persistent session only when mixed-language memory is desired.
