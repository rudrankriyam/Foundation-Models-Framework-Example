# Plan

This plan audits refactor targets in the Foundation Lab codebase, focusing on reducing duplication, separating concerns, and aligning with the (unseen) GH refactor issue.

## Requirements
- Align scope and acceptance criteria with the GH refactor issue (see Open questions).
- Preserve current behavior/UI; refactor for structure, reuse, and testability.
- Avoid changes to sample behavior and public UX unless explicitly requested.

## Audit findings
- `Foundation Lab/ViewModels/ContentViewModel.swift` appears unused beyond `Foundation Lab/Views/Examples/ExamplesView.swift` state; examples now use `ExampleExecutor`, so this is likely legacy.
- Error handling for `LanguageModelSession` is duplicated across `Foundation Lab/ViewModels/ContentViewModel.swift`, `Foundation Lab/ViewModels/ChatViewModel.swift`, `Foundation Lab/Views/Components/ToolViewBase.swift`, `Foundation Lab/Views/Examples/Components/ExampleExecutor.swift`, and `Foundation Lab/Views/Tools/RemindersToolViewHelpers.swift`.
- Tool views are inconsistent: some use `ToolExecutor` (`Foundation Lab/Views/Tools/ContactsToolView.swift`, `Foundation Lab/Views/Tools/CalendarToolView.swift`), others duplicate session/execution logic (`Foundation Lab/Views/Tools/WeatherToolView.swift`, `Foundation Lab/Views/Tools/WebToolView.swift`).
- Chat and Health chat duplicate session management, summary generation, transcript extraction, and windowing logic (`Foundation Lab/ViewModels/ChatViewModel.swift`, `Foundation Lab/Health/ViewModels/HealthChatViewModel.swift`, `Foundation Lab/Extensions/Transcript+TokenCounting.swift`).
- `Foundation Lab/Voice/Services/InferenceService.swift` defines `instructions` but never applies them to its `LanguageModelSession`.
- `Foundation Lab/Views/Components/ToolViewBase.swift` combines UI, banners, result display, and execution helper in one large file.
- Dynamic schema helper files are very large and repetitive across examples (`Foundation Lab/Views/Examples/DynamicSchemas/*Helpers.swift`).
- Enum models include view construction, mixing UI and data (`Foundation Lab/Models/ExampleType.swift` and `LanguageExample`/`ToolExample` factories), while other routes are in view files (`Foundation Lab/Views/Examples/SchemaExamplesView.swift`).
- `Foundation Lab/Health/Models/HealthDataManager.swift` mixes HealthKit queries, UI state updates, and persistence responsibilities.

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
[ ] Decide fate of `ContentViewModel` (remove legacy or integrate with current ExampleExecutor flow).
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
- Please paste or link the GH issue so the plan can align with its scope and constraints.
- Any refactor priorities (e.g., tools first vs. chat vs. dynamic schemas)?
- Should `ContentViewModel` be removed or retained for a specific UX?
