# 🚀 Issue Draft: Add `FoundationLabCLI` target with feature-parity commands

## Summary
Create a **new CLI target** (`FoundationLabCLI`) that exposes every user-facing app capability as command-line commands, while preserving current iOS/macOS app behavior.

The CLI should:
- Run on **macOS 26+** with Apple Intelligence enabled.
- Work in **simulator/headless-like workflows** where possible.
- Provide **clear capability gating** for device-only features (HealthKit, Music subscription, microphone/speech, etc.).
- Mirror app semantics for chat, tools, schemas, languages, RAG, and diagnostics.

---

## Why
Today, core functionality is primarily accessible through SwiftUI flows. We need a command surface for:
- Automation and scripting.
- CI-like smoke checks on supported Apple runtimes.
- Faster iteration on prompts/tools without launching UI.
- Parity across app and terminal workflows.

---

## Current state (source-of-truth inventory)

### Navigation groups to mirror in CLI
- `examples`
- `tools`
- `schemas`
- `languages`
- `settings` (CLI-relevant subset only)

### Current feature buckets

#### 1) Chat / session behavior
- Multi-turn chat with streaming
- Sliding window context management + summarization fallback
- Sampling strategy + guardrails toggles
- Feedback logging
- Voice mode (STT/TTS) in chat input flow

#### 2) Tools (9)
- Weather
- Web Search (Search1)
- Contacts
- Calendar
- Reminders
- Location
- Health
- Music
- Web Metadata

#### 3) Examples
- One-shot
- Journaling (structured)
- Creative writing (structured)
- Structured data
- Streaming response
- Model availability
- Generation guides
- Generation options
- Health dashboard
- RAG chat

#### 4) Dynamic schemas (11)
- Basic object
- Array schema
- Enum schema
- Nested objects
- Schema references
- Generation guides
- `@Generable` pattern
- Union types
- Form builder
- Error handling
- Invoice processing

#### 5) Languages
- Language detection / supported languages
- Multilingual responses
- Session management demo
- Production nutrition analysis example

#### 6) RAG
- Index file
- Index text
- Load sample docs
- Ask question + cite sources
- Reset DB

#### 7) Health module
- Health dashboard data paths + AI encouragement
- Health chat using tools (`HealthDataTool`, `HealthAnalysisTool`)
- HealthKit + SwiftData persistence paths

### File-by-file implementation map (for extraction planning)

#### App entry and navigation
- `Foundation Lab/FoundationLabApp.swift`
- `Foundation Lab/Views/AdaptiveNavigationView.swift`
- `Foundation Lab/Views/SidebarView.swift`
- `Foundation Lab/Models/NavigationCoordinator.swift`
- `Foundation Lab/Models/TabSelection.swift`

#### Intent surfaces (already command-like semantics)
- `Foundation Lab/AppIntents/OpenChatIntent.swift`
- `Foundation Lab/AppIntents/OpenExampleIntent.swift`
- `Foundation Lab/AppIntents/OpenToolIntent.swift`
- `Foundation Lab/AppIntents/OpenSchemaIntent.swift`
- `Foundation Lab/AppIntents/OpenLanguageIntent.swift`
- `Foundation Lab/AppIntents/AppIntentDestinations.swift`

#### Core model/session/chat behavior
- `Foundation Lab/ViewModels/ChatViewModel.swift`
- `Foundation Lab/Services/ConversationContextBuilder.swift`
- `Foundation Lab/Extensions/Transcript+TokenCounting.swift`
- `Foundation Lab/Models/AppConfiguration.swift`
- `Foundation Lab/Models/FoundationModelsError.swift`
- `Foundation Lab/Views/Chat/ChatView.swift`
- `Foundation Lab/Views/Components/ChatInputView.swift`
- `Foundation Lab/Views/Chat/ChatInstructionsView.swift`

#### Tool system and tool UIs
- `Foundation Lab/Services/ToolExecutor.swift`
- `Foundation Lab/Models/ExampleType.swift` (`ToolExample`)
- `Foundation Lab/Views/Tools/ToolExample+Destination.swift`
- `Foundation Lab/Views/Tools/ToolsView.swift`
- `Foundation Lab/Views/Tools/WeatherToolView.swift`
- `Foundation Lab/Views/Tools/WebToolView.swift`
- `Foundation Lab/Views/Tools/Search1WebSearchTool.swift`
- `Foundation Lab/Views/Tools/ContactsToolView.swift`
- `Foundation Lab/Views/Tools/CalendarToolView.swift`
- `Foundation Lab/Views/Tools/RemindersToolView.swift`
- `Foundation Lab/Views/Tools/RemindersToolViewHelpers.swift`
- `Foundation Lab/Views/Tools/LocationToolView.swift`
- `Foundation Lab/Views/Tools/HealthToolView.swift`
- `Foundation Lab/Views/Tools/MusicToolView.swift`
- `Foundation Lab/Views/Tools/WebMetadataToolView.swift`

#### Examples
- `Foundation Lab/Views/Examples/ExamplesView.swift`
- `Foundation Lab/Views/Examples/Components/ExampleExecutor.swift`
- `Foundation Lab/Views/Examples/BasicChatView.swift`
- `Foundation Lab/Views/Examples/JournalingView.swift`
- `Foundation Lab/Views/Examples/CreativeWritingView.swift`
- `Foundation Lab/Views/Examples/StructuredDataView.swift`
- `Foundation Lab/Views/Examples/GenerationGuidesView.swift`
- `Foundation Lab/Views/Examples/StreamingResponseView.swift`
- `Foundation Lab/Views/GenerationOptionsView.swift`
- `Foundation Lab/Views/GenerationOptionsHelpers.swift`
- `Foundation Lab/Views/Examples/ModelAvailabilityView.swift`
- `Foundation Lab/Views/ModelUnavailableView.swift`

#### Dynamic schemas
- `Foundation Lab/Models/DynamicSchemaExampleType.swift`
- `Foundation Lab/Views/Examples/SchemaExamplesView.swift`
- `Foundation Lab/Views/Examples/DynamicSchemas/DynamicSchemaExecutorExtension.swift`
- `Foundation Lab/Views/Examples/DynamicSchemas/DynamicSchemaHelpers.swift`
- `Foundation Lab/Views/Examples/DynamicSchemas/BasicDynamicSchemaView.swift`
- `Foundation Lab/Views/Examples/DynamicSchemas/ArrayDynamicSchemaView.swift`
- `Foundation Lab/Views/Examples/DynamicSchemas/EnumDynamicSchemaView.swift`
- `Foundation Lab/Views/Examples/DynamicSchemas/NestedDynamicSchemaView.swift`
- `Foundation Lab/Views/Examples/DynamicSchemas/ReferencedSchemaView.swift`
- `Foundation Lab/Views/Examples/DynamicSchemas/GuidedDynamicSchemaView.swift`
- `Foundation Lab/Views/Examples/DynamicSchemas/GenerablePatternView.swift`
- `Foundation Lab/Views/Examples/DynamicSchemas/UnionTypesSchemaView.swift`
- `Foundation Lab/Views/Examples/DynamicSchemas/FormBuilderSchemaView.swift`
- `Foundation Lab/Views/Examples/DynamicSchemas/SchemaErrorHandlingView.swift`
- `Foundation Lab/Views/Examples/DynamicSchemas/InvoiceProcessingSchemaView.swift`

#### Language features
- `Foundation Lab/Services/LanguageService.swift`
- `Foundation Lab/Views/Integrations/LanguagesIntegrationsView.swift`
- `Foundation Lab/Views/Languages/LanguageDetectionView.swift`
- `Foundation Lab/Views/Languages/MultilingualResponsesView.swift`
- `Foundation Lab/Views/Languages/SessionManagementView.swift`
- `Foundation Lab/Views/Languages/ProductionLanguageExampleView.swift`
- `Foundation Lab/Views/Languages/ProductionLanguageExampleHelpers.swift`

#### RAG features
- `Foundation Lab/Services/RAGService.swift`
- `Foundation Lab/ViewModels/RAGChatViewModel.swift`
- `Foundation Lab/Views/Examples/RAGChatView.swift`
- `Foundation Lab/Views/Examples/RAGChatView+Types.swift`
- `Foundation Lab/Views/Chat/RAGDocumentPickerView.swift`

#### Health features
- `Foundation Lab/Views/Examples/HealthExampleView.swift`
- `Foundation Lab/Health/Views/Dashboard/HealthDashboardView.swift`
- `Foundation Lab/Health/Views/Chat/HealthChatView.swift`
- `Foundation Lab/Health/ViewModels/HealthChatViewModel.swift`
- `Foundation Lab/Health/Tools/HealthDataTool.swift`
- `Foundation Lab/Health/Models/AI/HealthAnalysisTool.swift`
- `Foundation Lab/Health/Models/HealthDataManager.swift`
- `Foundation Lab/Health/Services/HealthKitService.swift`

#### Voice and permission stack
- `Foundation Lab/Voice/Services/PermissionManager.swift`
- `Foundation Lab/Voice/Services/SpeechRecognizer.swift`
- `Foundation Lab/Voice/Services/SpeechSynthesizer.swift`
- `Foundation Lab/Voice/Services/InferenceService.swift`

#### Build and target config
- `FoundationLab.xcodeproj/project.pbxproj`
- `FoundationLab.xcodeproj/xcshareddata/xcschemes/Foundation Lab.xcscheme`
- `Foundation Lab/FoundationLab.entitlements`
- `README.md`

---

## Constraints and environment realities

### Hard platform constraints
- Foundation Models calls require Apple runtime + Apple Intelligence (macOS/iOS 26+).
- True Linux/non-Apple runtime cannot execute Foundation Models natively today.

### Feature-specific constraints
- Likely simulator/headless-friendly:
  - One-shot/structured/streaming generation
  - Dynamic schemas
  - Web Search, Weather, Web Metadata
  - RAG with local text/docs
  - Language examples
- Device/permission/subscription-sensitive:
  - Contacts, Calendar, Reminders, Location
  - Health / HealthKit
  - Music (authorization + active subscription)
  - Voice STT/TTS flows

### Requirement
CLI must **never fail opaquely** for unsupported environments.
It should return machine-readable capability errors with remediation hints.

---

## Proposed command UX (GH CLI-inspired)

### Principles
- Noun-first subcommands (`tools weather`, `examples run`, `rag ask`).
- Human output by default, structured output via `--json`.
- Consistent exit codes.
- Deterministic command names and flags.
- Discoverability via rich `--help` and examples.

### Global flags
- `--json` output mode (stable schema per command).
- `--verbose` include prompt/session/debug metadata.
- `--quiet` suppress non-essential text.
- `--no-color` for non-interactive logs.
- `--timeout <seconds>` optional request timeout.
- `--dry-run` (where applicable) to preview prompt/tool call request shape.

---

## Proposed command tree (v1 target shape)

```text
foundationlab
  about
  diagnostics
    model-availability
    capabilities
  chat
    send
    stream
    interactive
    reset
  examples
    list
    run <example-id>
  tools
    list
    weather
    web-search
    contacts
    calendar
    reminders
    location
    health
    music
    web-metadata
  schemas
    list
    run <schema-id>
  languages
    list-supported
    multilingual-play
    session-demo
    analyze-nutrition
  rag
    status
    index-file
    index-text
    index-samples
    search
    ask
    reset
  health
    fetch
    analyze
    chat
  voice
    check
```

---

## Canonical ID mapping (app enums -> CLI identifiers)

### Example IDs (`ExampleType`)
- `basic_chat` -> `examples run basic_chat`
- `journaling` -> `examples run journaling`
- `creative_writing` -> `examples run creative_writing`
- `structured_data` -> `examples run structured_data`
- `streaming_response` -> `examples run streaming_response`
- `model_availability` -> `examples run model_availability`
- `generation_guides` -> `examples run generation_guides`
- `generation_options` -> `examples run generation_options`
- `health` -> `examples run health`
- `rag` -> `examples run rag`
- `chat` -> `chat interactive` / `chat send` / `chat stream`

### Tool IDs (`ToolExample`)
- `weather` -> `tools weather`
- `web` -> `tools web-search`
- `contacts` -> `tools contacts`
- `calendar` -> `tools calendar`
- `reminders` -> `tools reminders`
- `location` -> `tools location`
- `health` -> `tools health`
- `music` -> `tools music`
- `webMetadata` -> `tools web-metadata`

### Schema IDs (`DynamicSchemaExampleType`)
- `basic_object` -> `schemas run basic_object`
- `array_schema` -> `schemas run array_schema`
- `enum_schema` -> `schemas run enum_schema`
- `nested_objects` -> `schemas run nested_objects`
- `schema_references` -> `schemas run schema_references`
- `generation_guides` -> `schemas run generation_guides`
- `generable_pattern` -> `schemas run generable_pattern`
- `union_types` -> `schemas run union_types`
- `form_builder` -> `schemas run form_builder`
- `error_handling` -> `schemas run error_handling`
- `invoice_processing` -> `schemas run invoice_processing`

### Language IDs (`LanguageExample`)
- `language_detection` -> `languages list-supported`
- `multilingual_responses` -> `languages multilingual-play`
- `session_management` -> `languages session-demo`
- `production_example` -> `languages analyze-nutrition`

---

## Detailed command spec by feature

## `diagnostics`

### `foundationlab diagnostics model-availability`
- Mirrors model availability checks.
- Output includes:
  - `status`: available/unavailable
  - `reason`: `deviceNotEligible | appleIntelligenceNotEnabled | modelNotReady | unknown`
  - `remediation`

### `foundationlab diagnostics capabilities`
- Aggregated environment capability snapshot:
  - foundation model availability
  - tool availability map
  - health/music/voice readiness states

---

## `chat`

### `foundationlab chat send --message "..."`
- Single turn, persistent transcript file optional.
- Flags:
  - `--instructions`
  - `--sampling default|greedy|top-k`
  - `--top-k`
  - `--fixed-seed`
  - `--seed`
  - `--guardrails default|permissive`
  - `--session <path>` (persisted session/transcript)

### `foundationlab chat stream --message "..."`
- Streaming text to stdout.
- Same generation flags as `chat send`.

### `foundationlab chat interactive`
- REPL style loop.
- Special commands:
  - `/reset`
  - `/config`
  - `/save <path>`
  - `/exit`

### `foundationlab chat reset --session <path>`
- Clears persisted session state.

---

## `examples`

### `foundationlab examples list`
- IDs aligned with app enums:
  - `basic_chat`
  - `journaling`
  - `creative_writing`
  - `structured_data`
  - `streaming_response`
  - `model_availability`
  - `generation_guides`
  - `generation_options`
  - `health`
  - `rag`

### `foundationlab examples run <example-id>`
- Shared flags:
  - `--prompt`
  - `--instructions`
  - `--stream`
  - `--json`
- Example-specific flags:
  - `generation_options`: `--temperature`, `--sampling-mode`, `--top-k`, `--top-p`, `--max-response-tokens`
  - `model_availability`: no prompt; delegates to diagnostics command

---

## `tools`

### `foundationlab tools list`
- Shows all tool IDs and runtime availability.

### `foundationlab tools weather --location "San Francisco"`
- Prompt adapter: weather query by location.

### `foundationlab tools web-search --query "..." [--max-results 5]`
- Uses Search1 tool path.

### `foundationlab tools contacts --query "John"`
- Fails with actionable permission guidance if unavailable.

### `foundationlab tools calendar --query "What events do I have today?"`
- Inject timezone/locale/current datetime like app flow.

### `foundationlab tools reminders`
Modes:
- Quick create:
  - `--title`
  - `--notes`
  - `--due-date "yyyy-MM-dd HH:mm:ss"`
  - `--priority none|low|medium|high`
- Custom:
  - `--prompt`

### `foundationlab tools location`
- Requests current location summary via tool call.

### `foundationlab tools health --query "..."`
- Uses existing date guidance prompt strategy from app tool view.

### `foundationlab tools music --query "..."`
- Preflight:
  - authorization status
  - active subscription capability

### `foundationlab tools web-metadata --url "https://..."`
- URL validation required (`http/https`, valid host).

---

## `schemas`

### `foundationlab schemas list`
- IDs:
  - `basic_object`
  - `array_schema`
  - `enum_schema`
  - `nested_objects`
  - `schema_references`
  - `generation_guides`
  - `generable_pattern`
  - `union_types`
  - `form_builder`
  - `error_handling`
  - `invoice_processing`

### `foundationlab schemas run <schema-id>`
- Shared:
  - `--input "<text>"` or `--input-file <path>`
  - `--pretty`
- Schema-specific options:
  - `array_schema`: `--min-items`, `--max-items`
  - `enum_schema`: `--custom-choices "a,b,c"`
  - `nested_objects`: `--nesting-depth`
  - `form_builder`: `--mode`, `--include-validation`
  - `invoice_processing`: `--mode`, `--include-line-items`, `--calculate-totals`
  - `error_handling`: `--scenario`, `--detailed`

---

## `languages`

### `foundationlab languages list-supported`
- Returns model-supported languages with localized display names.

### `foundationlab languages multilingual-play`
- Runs multilingual prompt set and outputs per-language response.

### `foundationlab languages session-demo`
- Replays mixed-language session example to demonstrate context retention.

### `foundationlab languages analyze-nutrition`
- Flags:
  - `--description "<food text>"`
  - `--language "<display name or locale code>"`
- Returns structured nutrition + localized insight text.

---

## `rag`

### `foundationlab rag status`
- Indexed source count + backend readiness.

### `foundationlab rag index-file --path <file>`
### `foundationlab rag index-text --title "..." --text "..."`
### `foundationlab rag index-samples`
### `foundationlab rag search --query "..."`
### `foundationlab rag ask --question "..."`
### `foundationlab rag reset`

Output requirements:
- include top chunks + source titles
- include citation identifiers used in answer

---

## `health`

> Note: These commands are best-effort and must gate on platform authorization.

### `foundationlab health fetch --data-type <today|weekly|steps|heartRate|sleep|activeEnergy|distance> [--refresh]`
- Direct mapping to `HealthDataTool` arguments.

### `foundationlab health analyze --analysis-type <daily|weekly|trends|correlations|comprehensive> [--days] [--focus-metrics] [--include-predictions]`
- Direct mapping to `HealthAnalysisTool` arguments.

### `foundationlab health chat [--session <path>]`
- Persistent multi-turn health assistant loop with tool calls.

---

## `voice`

### `foundationlab voice check`
- CLI-level capability probe only in v1.
- Reports microphone/speech authorization and synthesis readiness.

> Full voice conversational CLI is **deferred** (device/audio-session complexity + low utility in non-interactive CI contexts).

---

## Architecture proposal

## Target strategy

### Recommended near-term
Add a new **macOS Command Line Tool target**:
- Target name: `FoundationLabCLI`
- Deployment target: macOS 26.0+
- New scheme: `FoundationLabCLI`
- Entry point: `main.swift` using `swift-argument-parser`

### Recommended long-term
Extract shared logic into reusable module(s):
- `FoundationLabCore`
  - session factory
  - prompt builders
  - error normalization
  - context window/summarization engine
  - tool adapter facade
  - capabilities probe
- `FoundationLabCLI`
  - argument parsing
  - command routing
  - output formatting

---

## Extraction plan from current code

### Reuse candidates (move or mirror into core)
- `Services/ToolExecutor.swift` -> headless tool execution service.
- `Services/ConversationContextBuilder.swift` -> reusable conversation summarization context builder.
- `Models/FoundationModelsError.swift` -> shared error mapping for CLI exit codes/messages.
- `Services/RAGService.swift` + parts of `ViewModels/RAGChatViewModel.swift` -> RAG command services.
- `Services/LanguageService.swift` -> language capabilities service.
- `Views/Tools/Search1WebSearchTool.swift` -> custom tool implementation reusable in CLI.
- Health tools:
  - `Health/Tools/HealthDataTool.swift`
  - `Health/Models/AI/HealthAnalysisTool.swift`

### Avoid direct reuse without refactor
- SwiftUI views and viewmodels tightly coupled to UI state.
- Voice UI/state machine flows requiring AV/Speech event loops.

---

## Phased implementation plan

## Phase 0 — Scaffolding
- [ ] Create `FoundationLabCLI` target + scheme.
- [ ] Add `swift-argument-parser` dependency to CLI target.
- [ ] Add baseline commands: `about`, `diagnostics model-availability`.

## Phase 1 — Core text generation
- [ ] Implement `chat send`, `chat stream`, `chat interactive`.
- [ ] Implement generation options/guardrails flags.
- [ ] Implement transcript persistence format (`--session`).

## Phase 2 — Tool commands
- [ ] Implement `tools list`.
- [ ] Implement weather/web-search/web-metadata first.
- [ ] Add gated commands for contacts/calendar/reminders/location/music/health.
- [ ] Add machine-readable capability errors.

## Phase 3 — Examples + schemas + languages
- [ ] Implement `examples run`.
- [ ] Implement `schemas run`.
- [ ] Implement all language commands.

## Phase 4 — RAG
- [ ] Implement index/search/ask/reset/status commands.
- [ ] Add structured citation output.

## Phase 5 — Health/voice capability layer
- [ ] Add `health fetch/analyze/chat`.
- [ ] Add `voice check`.

## Phase 6 — Quality and docs
- [ ] End-to-end command docs with examples.
- [ ] Error code reference.
- [ ] Shell completion/man page output.

---

## Acceptance criteria
- [ ] Every app feature category has a CLI command mapping (`examples/tools/schemas/languages/chat/rag/health`).
- [ ] `--help` for all top-level and subcommands is comprehensive.
- [ ] `--json` output schema is stable and documented for each command.
- [ ] Unsupported capabilities fail with explicit reason + remediation.
- [ ] At least one command from each major group is validated in simulator/macOS runtime.
- [ ] Existing app behavior remains unchanged.

---

## Test plan (for implementation PRs)

### Automated
- CLI parser tests for flags/args validation.
- Service tests for prompt builders and capability guards.
- Snapshot tests for `--json` outputs.

### Runtime smoke tests (Apple runtime)
- `foundationlab diagnostics model-availability`
- `foundationlab chat send --message "hello"`
- `foundationlab tools weather --location "Cupertino"`
- `foundationlab schemas run basic_object --input "..."`
- `foundationlab rag index-text ... && foundationlab rag ask ...`

### Capability-gated tests
- Ensure deterministic error payloads when:
  - HealthKit unavailable
  - Music unauthorized/subscription absent
  - Speech/microphone denied

---

## Risks and mitigations

### Risk: duplicate logic between app and CLI
Mitigation:
- Introduce `FoundationLabCore`.
- Keep prompt templates and capability checks in shared services.

### Risk: permission/entitlement mismatch in CLI target
Mitigation:
- Build explicit preflight guards per command.
- Soft-fail with actionable output.

### Risk: over-promising Linux support
Mitigation:
- Document macOS 26+ as first-class support.
- Treat non-Apple runtime as out-of-scope unless alternate model backend is introduced.

---

## Open questions
- Should v1 include a full voice conversational command, or keep `voice check` only?
- Should `tools` support both:
  - prompt-driven calls (parity with app), and
  - typed argument calls (deterministic automation)?
- Where should session state live by default (`~/.foundationlab/` vs explicit `--session`)?
- Do we want a single `run` command + mode flags, or explicit subcommands for each feature?

---

## Suggested labels
- `enhancement`
- `cli`
- `architecture`
- `apple-intelligence`
- `foundation-models`

---

## Notes for assignee
- Keep app target unchanged while introducing CLI target.
- Prioritize shared-core extraction early to avoid parallel logic drift.
- Start with commands that work broadly in simulator/macOS environment, then layer gated commands.

