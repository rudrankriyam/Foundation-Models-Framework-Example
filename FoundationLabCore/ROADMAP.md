# FoundationLabCore Roadmap

This roadmap tracks the shared-capability refactor after the initial package boundary landed.

## Working rules

- Shared task logic, request/result models, and reusable Foundation Models-backed providers live in `FoundationLabCore`.
- SwiftUI views, App Intents, and CLI commands stay as thin adapters over the same capabilities.
- Additional packages are deferred until dependency pressure or platform constraints justify the split.
- Multi-turn chat stays last so the single-shot capability pattern is proven first.

## Completed

- `#110` Create `FoundationLabCore` and define dependency rules.
- `#112` Extract `GenerateBookRecommendation` as the first shared capability.
- `#113` Add the first task-oriented App Intent backed by `GenerateBookRecommendation`.
- `#114` Add the first thin CLI adapter over `GenerateBookRecommendation`.

## Next up

### `#115` AnalyzeNutrition

- Move nutrition-analysis request/result models into `FoundationLabCore`.
- Extract prompt construction from `ProductionLanguageExampleView`.
- Add a capability/use case plus a Foundation Models-backed provider in `FoundationLabCore`.
- Keep language selection in the UI while moving execution and mapping into shared code.
- Add focused core tests before wiring future App Intent or CLI adapters.

### `#116` Weather and Web Search

- Define bounded capability contracts for weather lookup and web search.
- Move feature logic out of `ToolExecutor` and tool views into shared use cases.
- Introduce provider seams for weather retrieval and web search backends.
- Preserve current tool UI behavior while making the capabilities reusable from non-UI adapters.
- Add provider-mocked tests so the first tool-backed capabilities are stable before expanding further.

### `#117` Richer App Intents

- Keep existing navigation intents working while capability-backed intents expand.
- Add task-oriented App Shortcuts around extracted shared capabilities.
- Introduce App Entities only where they meaningfully improve Shortcuts or Spotlight surfaces.
- Define the first Spotlight-oriented foundation only after capability inputs and outputs stabilize.
- Keep `perform()` methods thin and free of business logic.

### `#118` Shared Conversation Core

- Extract session, transcript-windowing, and streaming orchestration into `FoundationLabCore`.
- Keep `ChatViewModel` focused on presentation, not ownership of conversation rules.
- Make the shared conversation engine reusable from SwiftUI, CLI, and later voice/RAG adapters.
- Preserve reset semantics, token budgeting, and streaming behavior with explicit tests.
- Defer voice and RAG migration until the conversation core boundary is stable.

## CLI note

Closed PR `#108` is useful inspiration for command taxonomy and the `fm` surface area, but future CLI growth should continue to reuse `FoundationLabCore` rather than reimplement features in the executable layer.
