# Common Errors

Use this reference for Foundation Models errors, guardrails, retries, cancellation, and final verification.

## User-Facing Error Presenter

```swift
import FoundationModels

enum FoundationModelsErrorPresenter {
    static func message(for error: Error) -> String {
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
}
```

## Retry Policy

Retry only when the second attempt changes constraints.

Good retry changes:

- lower temperature
- reduce maximum tokens
- narrow instructions
- ask for fewer fields
- use a fresh session after context overflow

Bad retry changes:

- repeating the same prompt immediately
- hiding safety or medical constraints
- retrying write tools without user confirmation

## Cancellation

```swift
@MainActor
final class GenerationTaskStore {
    private var task: Task<Void, Never>?

    func replace(with newTask: Task<Void, Never>) {
        task?.cancel()
        task = newTask
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}
```

## Verification Checklist

- Model unavailable path works.
- Permission denied path works.
- Streaming cancellation stops UI updates.
- Structured generation handles decoding failure.
- Dynamic schemas pass dependencies for references.
- Tool outputs are bounded and privacy-aware.
- App Intents do not duplicate shared prompt logic.
- Health wording avoids diagnosis and prescription.
- Unsupported language path is user-facing.

## Build Commands

Use the target app's equivalent commands. For Foundation Lab:

```bash
xcodebuild -project FoundationLab.xcodeproj -scheme "Foundation Lab" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
cd FoundationLabCore && swift test
```
