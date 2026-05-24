# Voice

Use this reference for speech recognition, voice commands, text-to-speech responses, and voice-first Foundation Models flows.

Keep speech recognition, model inference, and speech synthesis as separate services. A voice feature should always support cancellation and visible state.

## State Machine

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
```

## View Model Shape

```swift
import FoundationModels
import Observation

@MainActor
@Observable
final class VoiceAssistantViewModel {
    var state: VoiceInteractionState = .idle
    var transcript = ""
    var response = ""

    private var task: Task<Void, Never>?

    func handleFinalTranscript(_ text: String) {
        task?.cancel()
        transcript = text
        state = .generating

        task = Task {
            do {
                let session = LanguageModelSession(
                    instructions: "Respond conversationally for spoken output. Keep it concise."
                )
                response = try await session.respond(to: Prompt(text)).content
                state = .speaking
                // Send `response` to an AVSpeechSynthesizer wrapper here.
            } catch {
                state = .failed(FoundationModelsErrorPresenter.message(for: error))
            }
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
        state = .idle
    }
}
```

## Voice Command Tool

Use tool calling when voice should perform app actions.

```swift
let session = LanguageModelSession(
    tools: [CreateReminderDraftTool()],
    instructions: Instructions("""
    Convert spoken requests into reminder drafts.
    Do not save anything until the user confirms.
    """)
)
```

## Permissions

Request microphone and speech recognition permission before entering the listening state. Permission denial should return to `.idle` or `.failed` with a clear recovery message.

## UX Checklist

- Show when the app is listening, thinking, and speaking.
- Provide a visible cancel button.
- Keep spoken responses shorter than text responses.
- Confirm before write actions.
- Handle interruptions such as phone calls, route changes, and app backgrounding.
- Avoid reading sensitive data aloud without explicit user action.
