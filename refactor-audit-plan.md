# Plan

This plan audits refactor targets in the Foundation Lab codebase, focusing on reducing duplication, separating concerns, and aligning with GH issue #54 (“Refactor code”).

## Requirements
- Align scope with GH issue #54’s goal: improve code quality and maintainability for a reference-quality app.
- Preserve current behavior/UI; refactor for structure, reuse, and testability.
- Avoid changes to sample behavior and public UX unless explicitly requested.

## Audit findings
- `Foundation Lab/ViewModels/ContentViewModel.swift` is still constructed and passed into `Foundation Lab/Views/Examples/ExamplesView.swift`, but its `execute*` methods are not referenced by any view. The example screens now run via `Foundation Lab/Views/Examples/Components/ExampleExecutor.swift` (e.g., `Foundation Lab/Views/Examples/BasicChatView.swift`, `Foundation Lab/Views/Examples/StructuredDataView.swift`, `Foundation Lab/Views/Examples/BusinessIdeasView.swift`).
  - What to change: remove `ContentViewModel` entirely and simplify `ExamplesView` so it no longer binds or renders shared response/loading UI for examples.
  - Where: `Foundation Lab/Views/AdaptiveNavigationView.swift` (state ownership), `Foundation Lab/Views/Examples/ExamplesView.swift` (binding and responseView/loadingView), and `Foundation Lab/ViewModels/ContentViewModel.swift` (legacy `execute*` methods).
  - Why: there are now two distinct example execution paths (legacy `ContentViewModel` + newer `ExampleExecutor`), which increases maintenance overhead and hides dead code paths.

- Error handling for `LanguageModelSession` is duplicated across multiple places: `Foundation Lab/ViewModels/ChatViewModel.swift` (`handleFoundationModelsError`), `Foundation Lab/ViewModels/ContentViewModel.swift` (`handleFoundationModelsError`), `Foundation Lab/Views/Examples/Components/ExampleExecutor.swift` (`handleError`), `Foundation Lab/Views/Components/ToolViewBase.swift` (`ToolExecutor.handleError`), and `Foundation Lab/Views/Tools/RemindersToolViewHelpers.swift` (`handleFoundationModelsError`).
  - What to change: consolidate into a single error mapping utility (e.g., `Foundation Lab/Models/FoundationModelsError.swift` or a new `Foundation Lab/Services/ModelErrorMapper.swift`) and call it everywhere.
  - Where: replace local functions in the files listed above with the shared helper; keep the shared helper close to `FoundationModelsErrorHandler` so error types stay centralized.
  - Why: reducing duplication avoids inconsistent messages and simplifies future updates when `FoundationModels` error cases change.

- Tool views are inconsistent about execution patterns. Some use `ToolExecutor` (`Foundation Lab/Views/Tools/ContactsToolView.swift`, `Foundation Lab/Views/Tools/CalendarToolView.swift`), while others duplicate session creation and error handling (`Foundation Lab/Views/Tools/WeatherToolView.swift`, `Foundation Lab/Views/Tools/WebToolView.swift`, and the custom flow in `Foundation Lab/Views/Tools/RemindersToolView.swift`).
  - What to change: standardize on `ToolExecutor` (or a successor) for all tool views, using shared components like `ToolInputField` and `ToolExecuteButton` where possible.
  - Where: migrate `WeatherToolView` and `WebToolView` to use `ToolExecutor`, and decide whether `RemindersToolView` should use `ToolExecutor` with `executeWithCustomSession` or keep a dedicated executor type for its dual-mode flow.
  - Why: consistent patterns reduce UI/logic drift and make it easier to add new tools.

- Chat and Health chat flows share similar responsibilities but use separate implementations. `Foundation Lab/ViewModels/ChatViewModel.swift` and `Foundation Lab/Health/ViewModels/HealthChatViewModel.swift` both implement:
  - transcript extraction from `Transcript.Entry` segments,
  - summarization requests with a new `LanguageModelSession`,
  - session recreation with embedded summary context,
  - and context window handling (explicit in `ChatViewModel`, implicit in Health). The token estimation helpers live in `Foundation Lab/Extensions/Transcript+TokenCounting.swift` and are used only by `ChatViewModel`.
  - What to change: extract shared transcript utilities (text extraction, summary prompt creation, session reset helpers, optional windowing policy) into a shared service or protocol with chat-specific configuration.
  - Where: new shared service under `Foundation Lab/Services` or `Foundation Lab/ViewModels/Shared`, then use it from both `ChatViewModel` and `HealthChatViewModel`. Consider moving transcript parsing logic out of each view model.
  - Why: this reduces duplicate logic and makes chat behavior more consistent between general chat and health coaching.

- `Foundation Lab/Voice/Services/InferenceService.swift` computes a large `instructions` string but never applies it to its `LanguageModelSession` (the session is created with default instructions). The only use of `instructions` is in `Foundation Lab/Voice/VoiceViewModel.swift` when prewarming (`inferenceService.session.prewarm(promptPrefix: Prompt(inferenceService.instructions))`).
  - What to change: either initialize the session with `Instructions(instructions)` or remove `instructions` entirely and keep the prewarm prompt as a local constant in `VoiceViewModel`.
  - Where: `Foundation Lab/Voice/Services/InferenceService.swift` and `Foundation Lab/Voice/VoiceViewModel.swift`.
  - Why: current behavior implies instructions are intended to shape responses, but they are only used during prewarming, which is inconsistent and easy to misunderstand.

- `Foundation Lab/Views/Components/ToolViewBase.swift` is a large mixed-responsibility file: base view layout, banners, result display, input controls, and `ToolExecutor` (execution logic) are all co-located.
  - What to change: split UI components into smaller files (e.g., `ToolViewBase.swift`, `ToolBanners.swift`, `ResultDisplay.swift`, `ToolInputs.swift`) and move `ToolExecutor` into a dedicated file under `Foundation Lab/Services` or `Foundation Lab/ViewModels`.
  - Where: extract struct definitions currently in `ToolViewBase.swift` into new files and update imports.
  - Why: large multi-purpose files are harder to navigate and test; separating UI from execution logic clarifies responsibilities.

- Dynamic schema helpers are very large and repetitive across example modules, with similar schema construction patterns and string formatting. For instance, `Foundation Lab/Views/Examples/DynamicSchemas/NestedDynamicSchemaHelpers.swift` and `Foundation Lab/Views/Examples/DynamicSchemas/ReferencedSchemaHelpers.swift` each re-implement schema builders and example code strings.
  - What to change: introduce shared builder utilities or data-driven schema definitions (e.g., arrays of `DynamicGenerationSchema.Property` or typed builder functions) and reuse across examples; move shared formatting to a common helper.
  - Where: add a shared helper under `Foundation Lab/Views/Examples/DynamicSchemas/Shared` and update each example helper to call into it.
  - Why: reduces file size, eliminates repeated patterns, and makes it easier to add new schema examples.

- Enum models mix data with view construction. `Foundation Lab/Models/ExampleType.swift` contains `ToolExample.createView()` and `LanguageExample.createView()` factories that directly instantiate SwiftUI views, while schema routing is already handled in `Foundation Lab/Views/Examples/SchemaExamplesView.swift` via a view-layer `switch`.
  - What to change: keep routing where navigation happens (SwiftUI‑ish). Remove view construction from enums and use `.navigationDestination(for:)` with a local `switch` in the view. Optional: extract the `switch` into a `Views/` extension on the enum for reuse.
  - Where: remove `createView()` from `ToolExample`/`LanguageExample` in `Foundation Lab/Models/ExampleType.swift`; move the `switch` into `Foundation Lab/Views/Tools/ToolsView.swift` and `Foundation Lab/Views/Integrations/LanguagesIntegrationsView.swift` (or a `Views/` extension file).
  - Why: keeps model enums UI‑agnostic, reduces coupling, and aligns with SwiftUI’s expected navigation style.

- `Foundation Lab/Health/Models/HealthDataManager.swift` spans HealthKit access, UI-facing observable state, and persistence (`SwiftData`) in one class.
  - What to change: split into (1) a HealthKit query service, (2) a persistence repository for `HealthMetric`/`HealthInsight`, and (3) a lightweight observable model for view consumption.
  - Where: new files under `Foundation Lab/Health/Services` and `Foundation Lab/Health/Repositories`, then update `HealthChatViewModel` and health views to depend on the new abstractions.
  - Why: separation improves testability and reduces the risk of unintended side effects when fetching or storing health data.

## Scope
- In:
  - Consolidate session creation + error handling into shared utilities.
  - Standardize tool execution via `ToolExecutor`.
  - Extract shared chat/session management.
  - Split oversized, mixed-responsibility files.
  - Decouple model enums from view creation/routing.
  - Normalize dynamic schema example definitions.
  - Fix/clarify `InferenceService` instructions usage.
- Out:
  - Feature changes, UX redesigns, or API/behavior changes.

## Files and entry points
- `Foundation Lab/ViewModels/ChatViewModel.swift`
- `Foundation Lab/Health/ViewModels/HealthChatViewModel.swift`
- `Foundation Lab/Views/Components/ToolViewBase.swift`
- `Foundation Lab/Views/Examples/Components/ExampleExecutor.swift`
- `Foundation Lab/Views/Tools/*ToolView.swift`
- `Foundation Lab/ViewModels/ContentViewModel.swift`
- `Foundation Lab/Models/ExampleType.swift`
- `Foundation Lab/Views/Examples/SchemaExamplesView.swift`
- `Foundation Lab/Views/Examples/DynamicSchemas/*Helpers.swift`
- `Foundation Lab/Health/Models/HealthDataManager.swift`
- `Foundation Lab/Voice/Services/InferenceService.swift`

## Data model / API changes
- None expected; refactor should be internal-only.

## Action items
[ ] Capture the GH issue details (scope, acceptance criteria, priority areas).
[ ] Map shared session/error-handling code paths across `ExampleExecutor`, `ToolExecutor`, and view models; define a single shared utility or protocol.
[ ] Standardize tool views to use `ToolExecutor` + shared inputs (`ToolInputField`, `ToolExecuteButton`) and remove duplicated session code.
[ ] Extract shared chat/session utilities (transcript parsing, summarization, sliding window) into a reusable service used by both Chat and Health chat.
[ ] Remove `ContentViewModel` and simplify `ExamplesView` to eliminate the unused response/loading panel.
[ ] Split `ToolViewBase` into smaller UI components and move `ToolExecutor` to its own file/module.
[ ] Refactor dynamic schema examples to data-driven builders to reduce the large helper files.
[ ] Decouple enum models from view creation by moving routing to view-layer factories.
[ ] Clarify and apply `InferenceService` instructions to its session (or remove the unused field).
[ ] Evaluate `HealthDataManager` for separation into a query service + persistence repository.

## Testing and validation
- Build and run the app in Xcode.
- Smoke test: Chat, Tools, Schemas, Languages, Voice, Health flows.
- Verify session/windowing and summarization still behave as before.

## Risks and edge cases
- Subtle behavior changes in chat summarization or token windowing.
- Tool prompt changes can alter tool-call outputs.
- HealthKit permission flows and persistence are sensitive to timing and threading.

## Open questions
- Any refactor priorities (e.g., tools first vs. chat vs. dynamic schemas)?
- Do you want any shared response/loading UI on the Examples landing screen, or should all results stay within each example view?
