---
name: foundation-models-app-builder
description: Build or modify Apple Foundation Models features in Swift, SwiftUI, iOS, and macOS apps using Foundation Lab's working app patterns. Use when adding or reviewing LanguageModelSession flows, structured generation with @Generable or DynamicGenerationSchema, tool calling, RAG, voice input/output, HealthKit-backed AI, multilingual responses, App Intents, model availability checks, context management, or FoundationLabCore-style reusable capability boundaries.
---

# Foundation Models App Builder

Use this skill to build shippable Foundation Models features from the Foundation Lab example app, not isolated API snippets. Prefer repo-backed patterns, availability gates, capability boundaries, and verification steps over speculative code.

## Workflow

1. Identify the feature shape: one-shot text, streaming, structured generation, dynamic schema, tool calling, RAG, voice, HealthKit, multilingual, App Intent, or shared capability extraction.
2. Inspect the target app and the matching Foundation Lab path before proposing code. Use the routing table below.
3. Keep reusable task logic in `FoundationLabCore`-style request/result/provider/use-case layers when the feature must be shared by SwiftUI, App Intents, or other adapters.
4. Keep SwiftUI, permissions, navigation, and screen state in the app target. Do not put `SwiftUI`, `AppIntents`, or UI state into shared core code.
5. Add availability checks and user-facing fallback behavior for Apple Intelligence, unsupported platforms, permissions, and unavailable languages.
6. Verify with the narrowest build or test command that covers the changed surface.

## Route By Task

- **Architecture or extraction**: Read `references/architecture.md`.
- **Finding working examples**: Read `references/feature-map.md`.
- **Structured output, `@Generable`, guides, dynamic schemas**: Read `references/structured-generation.md`.
- **Tools, RAG, voice, HealthKit, permissions**: Read `references/integrations.md`.
- **Build, validation, and release checks**: Read `references/verification.md`.

## Core Rules

- Prefer `FoundationLabCore/Sources/FoundationLabCore/Capabilities/*UseCase.swift` for reusable task boundaries.
- Prefer request/result structs for inputs and outputs instead of passing raw prompts through UI layers.
- Prefer provider protocols plus Foundation Models-backed implementations when a capability may need dry-run, tests, alternate providers, or adapter reuse.
- Use `@Observable` and `@MainActor` for SwiftUI-facing view models in this repo.
- Use direct Foundation Models APIs in app views only when the file is intentionally an educational example.
- Treat tool calling as app integration work: model intent, permissions, data access, failures, and user confirmation all matter.
- Do not assume Foundation Models are available. Check availability and preserve the repo's `ModelUnavailableView` style of graceful handling.

## Common Traps

- Do not make dynamic schemas the default. Use `@Generable` when the output type is known at compile time.
- Do not bury permission prompts inside model calls. Request and explain Contacts, Calendar, Reminders, Location, HealthKit, Music, Speech, and Microphone access at the UI or service boundary.
- Do not let a streaming loop update SwiftUI too aggressively. Keep UI updates main-actor safe and cancellable.
- Do not leak prompt orchestration into every screen. Extract repeated flows into shared providers or use cases.
- Do not add App Intent-only logic when the same task should also work from the app UI.

## Useful Repo Commands

```bash
xcodebuild -project FoundationLab.xcodeproj -scheme "Foundation Lab" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
cd FoundationLabCore && swift test
```
