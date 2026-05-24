# App Intents

Use this reference when exposing Foundation Models features to Shortcuts, Spotlight, Siri, controls, or app shortcuts.

App Intents should be thin adapters over shared capabilities. Avoid duplicating prompt orchestration in intent files when the same feature exists in the app UI.

## Intent Over Shared Use Case

```swift
import AppIntents

struct SummarizeNotesIntent: AppIntent {
    static let title: LocalizedStringResource = "Summarize Notes"
    static let description = IntentDescription("Summarizes notes with on-device Foundation Models.")

    @Parameter(title: "Notes")
    var notes: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let result = try await GenerateSummaryUseCase().execute(notes: notes)
        return .result(value: result.content)
    }
}
```

## Direct Intent For Small Features

For a tiny one-off intent, keep the model call compact and move it into a use case later if the app UI also needs it.

```swift
import AppIntents
import FoundationModels

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

## App Shortcut

```swift
struct FoundationModelsShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SummarizeNotesIntent(),
            phrases: [
                "Summarize notes with \(.applicationName)",
                "Use \(.applicationName) to summarize notes"
            ],
            shortTitle: "Summarize Notes",
            systemImageName: "sparkles"
        )
    }
}
```

## Intent Checklist

- Keep parameters small and clear.
- Return concise values for Siri and Shortcuts.
- Validate empty input before model generation.
- Avoid long-running multi-turn sessions in intents.
- Use shared use cases for tasks also available in SwiftUI.
- For write actions, return a draft or ask for confirmation before committing data.
