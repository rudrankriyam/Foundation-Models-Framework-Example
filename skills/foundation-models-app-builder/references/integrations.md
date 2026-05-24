# Integrations

Use this reference for tool calling, RAG, voice, HealthKit, App Intents, and other app integrations.

## Tool Calling

Treat tools as product integrations with model-facing descriptions and app-facing safety boundaries.

Before adding a tool, define:

- the user intent it supports
- required permissions or API access
- model-visible input and output shape
- failure cases and user-facing recovery
- whether the action reads data, writes data, or requires confirmation

Inspect:

- `FoundationLabCore/Sources/FoundationLabCore/Providers/FoundationModelsToolInvoker.swift`
- `FoundationLabCore/Sources/FoundationLabCore/Tools/Search1WebSearchTool.swift`
- `Foundation Lab/Views/Tools/`
- `Foundation Lab/AppIntents/`
- `BookPlaygrounds/08_BasicToolUse/`

## RAG

Use RAG for user-provided or app-provided documents that should ground responses. Keep retrieval, indexing, and prompt assembly separated from SwiftUI state.

Inspect:

- `Foundation Lab/Services/RAGService.swift`
- `Foundation Lab/ViewModels/RAGChatViewModel.swift`
- `Foundation Lab/Views/Examples/RAGChatView.swift`

Check cancellation, empty document states, reset behavior, and user-visible source handling.

## Voice

Voice features need a state machine, permission flow, speech recognition, model inference, text-to-speech, cancellation, and accessibility behavior.

Inspect:

- `Foundation Lab/Voice/VoiceViewModel.swift`
- `Foundation Lab/Voice/VoiceView.swift`
- `Foundation Lab/Voice/Services/`
- `Foundation Lab/Voice/State/`

Keep audio/session state separate from Foundation Models prompt logic. Do not let voice recording, model response generation, and speech synthesis collapse into one untestable method.

## HealthKit

Health features must be conservative with permissions, wording, and claims. Prefer insights and summaries over diagnosis.

Inspect:

- `Foundation Lab/Health/`
- `FoundationLabCore/Sources/FoundationLabCore/Capabilities/AnalyzeNutritionUseCase.swift`
- `FoundationLabCore/Sources/FoundationLabCore/Capabilities/QueryHealthDataUseCase.swift`
- `FoundationLabCore/Sources/FoundationLabCore/Providers/FoundationModelsHealthDataQuerier.swift`

Always handle denied HealthKit authorization and unavailable data.

## App Intents

App Intents should be thin adapters over shared capabilities. Avoid duplicating prompts or business logic in intent files.

Inspect:

- `Foundation Lab/AppIntents/GenerateBookRecommendationIntent.swift`
- `Foundation Lab/AppIntents/AnalyzeNutritionIntent.swift`
- `Foundation Lab/AppIntents/GetWeatherIntent.swift`
- `Foundation Lab/AppIntents/SearchWebIntent.swift`
- `Foundation Lab/AppIntents/FoundationLabAppShortcuts.swift`
