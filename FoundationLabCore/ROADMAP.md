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
- `#115` Extract `AnalyzeNutrition` into `FoundationLabCore`.
- `#116` Extract Weather and Web Search into shared capabilities with app, App Intent, and CLI adapters.
- Extract the remaining tool-backed capabilities for Contacts, Calendar, Reminders, Location, Music, Web Metadata, and Health into `FoundationLabCore`.
- Rewire the corresponding SwiftUI tool views so they invoke shared use cases instead of owning Foundation Models prompts and orchestration directly.
- Add capability-backed App Intents for nutrition, contacts, calendar, reminders, location, music, web page summary, and health queries.
- Extend the `fm` CLI with matching feature groups while returning consistent unsupported-environment errors for system-entitled capabilities outside the app.
- Add shared core primitives for one-shot text, structured generation, streaming text, dynamic schema generation, model availability, supported language listing, and a basic reusable multi-turn conversation runner.
- Rewire the example/language runtime surfaces so `ExampleExecutor`, model availability, supported-language loading, multilingual response generation, dynamic schema execution, and the session-management demo flow through `FoundationLabCore`.

## Next up

### Tool cleanup

- Remove or shrink any remaining app-local helper types that still exist only to support the old tool-owned Foundation Models flow.
- Audit for dead Foundation Models tool wrappers that are no longer used now that shared providers live in `FoundationLabCore`.
- Refresh user-facing docs and sample references so the shared-capability architecture is the default story.

### `#117` Richer App Intents

- Keep existing navigation intents working while capability-backed intents expand.
- Stay within the system limit of 10 App Shortcuts while keeping the broader set of App Intents available.
- Introduce App Entities only where they meaningfully improve Shortcuts or Spotlight surfaces.
- Define the first Spotlight-oriented foundation only after capability inputs and outputs stabilize.
- Keep `perform()` methods thin and free of business logic.

### `#118` Shared Conversation Core

- Expand the current shared conversation runner into the full session, transcript-windowing, summarization, and streaming engine used by chat.
- Keep `ChatViewModel` focused on presentation, not ownership of conversation rules.
- Make the shared conversation engine reusable from SwiftUI, CLI, and later voice/RAG adapters.
- Preserve reset semantics, token budgeting, and streaming behavior with explicit tests.
- Defer voice and RAG migration until the conversation core boundary is stable.

## CLI note

Closed PR `#108` is useful inspiration for command taxonomy and the `fm` surface area, but future CLI growth should continue to reuse `FoundationLabCore` rather than reimplement features in the executable layer.
