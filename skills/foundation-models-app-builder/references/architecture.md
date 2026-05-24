# Architecture

Use this reference when deciding where Foundation Models code belongs.

## Repo Shape

- `Foundation Lab/` is the iOS/macOS app target. Keep SwiftUI, navigation, permissions, app lifecycle, and screen-local state here.
- `FoundationLabCore/` is the shared task boundary. Keep reusable request/result models, provider protocols, use cases, domain errors, and Foundation Models-backed implementations here.
- `BookPlaygrounds/` contains educational snippets. Use these for teaching small API concepts, not as the default shape for production app code.
- `Agents.md` describes repo conventions for AI agents working in this codebase.

## Shared Capability Pattern

Prefer this pattern for reusable features:

1. Define a request in `FoundationLabCore/Sources/FoundationLabCore/Requests/`.
2. Define a result in `FoundationLabCore/Sources/FoundationLabCore/Results/`.
3. Define a provider protocol in `FoundationLabCore/Sources/FoundationLabCore/Providers/`.
4. Add a Foundation Models-backed provider implementation.
5. Add a task-oriented use case in `FoundationLabCore/Sources/FoundationLabCore/Capabilities/`.
6. Make SwiftUI, App Intents, and other adapters call the use case instead of owning prompt orchestration.

Examples to inspect:

- `GenerateBookRecommendationUseCase.swift`
- `AnalyzeNutritionUseCase.swift`
- `GenerateStructuredDataUseCase.swift`
- `GenerateDynamicSchemaContentUseCase.swift`
- `RunConversationUseCase.swift`
- `CheckModelAvailabilityUseCase.swift`

## Dependency Rules

- `FoundationLabCore` must not import `SwiftUI`, `AppIntents`, or UI frameworks.
- App targets may depend on `FoundationLabCore`.
- App Intents should be thin adapters over shared capabilities.
- Educational example views may show direct Foundation Models code, but runtime features should prefer shared capabilities once the pattern exists.

## Design Bias

Favor app-building patterns over API demos. A good change handles:

- availability and unsupported hardware
- cancellation and concurrency
- permission boundaries
- user-facing errors
- testability or dry-run seams
- localization when text reaches UI
