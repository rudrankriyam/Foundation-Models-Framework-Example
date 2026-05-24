---
name: foundation-models-app-builder
description: Build or modify Apple Foundation Models features in Swift, SwiftUI, iOS, and macOS apps. Use when adding or reviewing LanguageModelSession flows, model availability checks, streaming, GenerationOptions, @Generable structured output, DynamicGenerationSchema, tool calling, RAG, voice input/output, HealthKit-backed AI, multilingual responses, App Intents, reusable capability boundaries, or production error handling.
---

# Foundation Models App Builder

Use this skill as a self-contained Foundation Models app-building playbook. The recipes live inside this skill so agents can apply the patterns in any Swift app without needing to inspect the Foundation Lab repository.

## Workflow

1. Identify the feature shape: availability, one-shot text, streaming, structured output, dynamic schema, tool calling, RAG, voice, HealthKit, multilingual, App Intent, or reusable capability extraction.
2. Load only the reference file for that feature.
3. Start from the packaged Swift recipe, then adapt naming, UI, permissions, and domain models to the target app.
4. Keep reusable Foundation Models orchestration out of SwiftUI views when the feature will be shared by app screens, App Intents, CLI commands, widgets, or tests.
5. Add graceful fallback behavior for unavailable Apple Intelligence, unsupported languages, denied permissions, context-window overflow, rate limits, decoding failures, and guardrail refusals.
6. Verify with the narrowest build or test command that covers the changed surface.

## Reference Routing

- **Reusable architecture, use cases, providers, SwiftUI adapters, App Intent adapters**: `references/architecture.md`
- **Availability, sessions, instructions, streaming, generation options, token budgets, errors**: `references/foundation-models-recipes.md`
- **`@Generable`, `@Guide`, `DynamicGenerationSchema`, schema decoding and retries**: `references/structured-generation.md`
- **Tool calling, RAG, voice, HealthKit, multilingual, permissions**: `references/integrations.md`
- **Build commands, manual checks, PR checklist**: `references/verification.md`

## Core Rules

- Use `@Generable` when the output type is known at compile time.
- Use `DynamicGenerationSchema` only when the schema is built at runtime.
- Create a fresh `LanguageModelSession` for unrelated one-shot tasks; keep a session only when conversation memory matters.
- Put permissions and user confirmation at app boundaries, not inside model prompts.
- Keep streaming UI updates cancellable and main-actor safe.
- Avoid App Intent-only prompt logic. Shared tasks should be callable from the app UI too.
- Prefer compact, domain-specific instructions over giant prompts.
- Do not assume Foundation Models are available; check `SystemLanguageModel.default.availability`.
