# Multilingual

Use this reference for supported languages, language selection, multilingual responses, and code switching.

## Fresh Session Per Independent Language Task

Use fresh sessions when switching languages for independent tasks.

```swift
import FoundationModels

func canUseFoundationModels(for locale: Locale = .current) -> Bool {
    SystemLanguageModel.default.supportsLocale(locale)
}

enum MultilingualGenerationError: Error, LocalizedError {
    case unsupportedLocale

    var errorDescription: String? {
        switch self {
        case .unsupportedLocale:
            "Foundation Models does not support this language or locale on this device."
        }
    }
}

func respondInLanguage(
    prompt: String,
    languageName: String,
    locale: Locale = .current
) async throws -> String {
    guard canUseFoundationModels(for: locale) else {
        throw MultilingualGenerationError.unsupportedLocale
    }

    let session = LanguageModelSession(
        instructions: Instructions("Respond in \(languageName). Keep the answer concise.")
    )

    return try await session.respond(to: Prompt(prompt)).content
}
```

## Persistent Session For Code Switching

Use one persistent session when the user expects the model to remember prior messages across languages.

```swift
let session = LanguageModelSession(
    instructions: "Support code switching. Preserve meaning across languages."
)

let english = try await session.respond(to: Prompt("I am planning a trip to Kyoto."))
let spanish = try await session.respond(to: Prompt("Responde ahora en español."))
let memory = try await session.respond(to: Prompt("What city did I mention earlier?"))
```

## Language Selection Model

```swift
struct SupportedLanguageOption: Identifiable, Hashable, Sendable {
    var id: String { localeIdentifier }
    var localeIdentifier: String
    var displayName: String
    var nativeName: String
}
```

Use `supportsLocale(_:)` for eligibility checks because it accounts for language fallbacks. Use `supportedLanguages` when you need to display the model's language list.

## Unsupported Language Handling

```swift
func localizedGeneration(
    prompt: String,
    languageName: String
) async -> Result<String, String> {
    do {
        let text = try await respondInLanguage(prompt: prompt, languageName: languageName)
        return .success(text)
    } catch LanguageModelSession.GenerationError.unsupportedLanguageOrLocale {
        return .failure("This language is not supported by Foundation Models on this device.")
    } catch {
        return .failure(FoundationModelsErrorPresenter.message(for: error))
    }
}
```

## Prompt Rules

- Name the target language explicitly in instructions.
- Use fresh sessions for independent language outputs.
- Use persistent sessions for deliberate code switching.
- Localize user-facing fallback strings outside the model.
- Do not assume every device supports every language.
