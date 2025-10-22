# Adapter Studio – Detailed Plan & Specification

## 1. Vision & Objectives
- [ ] Deliver a standalone “Adapter Studio” target that lets developers compare baseline vs. adapter-enhanced language model responses side-by-side.
- [ ] Provide tooling to hot-reload locally trained `.fmadapter` artifacts without touching the production app target.
- [ ] Capture prompt/response history with adapter metadata to aid evaluation and regression tracking.

## 2. Success Criteria
- [ ] New Xcode target builds and runs independently of existing app targets.
- [ ] Developers can select or auto-discover a local adapter file and instantiate `SystemLanguageModel(adapter:)` without code changes outside the new target.
- [ ] Split-screen UI streams responses from both the base model and the adapter for the same prompt within one interaction cycle.
- [ ] Reloading the adapter (new file dropped in watched location) updates the adapted session without restarting the app.
- [ ] Persistent log of prompt, base response, adapter response, latency, and adapter version available per run.

## 3. Target Platform & Dependencies
- [ ] **Platform:** macOS SwiftUI app target (only).
- [ ] **Minimum OS:** macOS 26 (align with latest Foundation Models tooling).
- [ ] **Frameworks:** `SwiftUI`, `Combine`, `Observation`, `Foundation`, `OSLog`, `BackgroundTasks` (optional for draft compilation), and `FileWatcher` abstraction (custom).
- [ ] **Build Settings:** Separate bundle identifier (e.g., `com.rudrankriyam.foundation-model-adapterstudio`) and signing profile. Do not share code with existing app targets for the MVP.

## 4. High-Level Architecture
- [ ] **AdapterStudioApp** (new target):
  - [x] `AppDelegate` or `@main` entry.
  - [ ] Injects shared services via environment.
  - [ ] Maintains strict module isolation from existing production targets (no shared code for initial delivery).
- [ ] **Services**
  - [ ] `ModelCompareEngine`: Manages two `LanguageModelSession`s (base + adapter), coordinates prompts, aggregates telemetry.
  - [ ] `AdapterProvider`: Locates adapters via manual picker and exposes the active selection.
- [ ] **View Models**
  - [x] `CompareViewModel`: Handles prompt submission, streaming updates, request queueing.
  - [ ] `HistoryViewModel`: Surfaces saved transcripts.
- [ ] **Views**
  - [ ] `CompareWorkbenchView`: main split view with shared prompt input.
  - [ ] `SessionColumnView`: renders streaming tokens, latency, toggles.
  - [ ] `HistorySidebarView`: lists prior runs and adapter metadata.
  - [ ] `SettingsSheet`: choose adapter folder and manage adapter selection.
- [ ] **Utilities**
  - [ ] `LatencyTimer`, `TokenStreamAggregator` helpers.

## 5. Adapter Handling Strategy (Local-Only MVP)
- [ ] **Default Location:** Define a default directory (e.g., `~/Library/Application Support/AdapterStudio/Adapters`) configurable via Settings.
- [ ] **Manifest Support:** Optional JSON manifest describing `adapterName`, `version`, `systemModelVersion`, `checksum`.
- [ ] **Hot Reload Flow:**
  - [ ] Manual selection reloads the active adapter.
- [ ] **Error Handling:** Provide surfaced alerts for incompatible versions, missing entitlements, or load errors.

## 6. UI/UX Detailed Layout
- [ ] **Top Bar:**
  - [ ] Prompt text editor (multi-line, syntax highlighted optional).
  - [ ] Controls: “Run”, “Clear”, “Reload Adapter”, “Save Transcript”.
  - [ ] Status indicators for adapter version, base model availability, draft compile state.
- [ ] **Main Body:** Two columns in `HStack`
  - [ ] **Left:** “Base Model” – streaming text output, token/latency badges, skeleton placeholders during load.
  - [ ] **Right:** “Adapter” – identical layout plus highlight of deltas.
  - [ ] Support optional diff overlay toggle (color-coded insert/delete).
- [ ] **Bottom Drawer / Sidebar:**
  - [ ] History list with selectable entries.
  - [ ] Metadata view (prompt, adapter version, draft compile timestamp).
- [ ] **Notifications:** Toast/banner for file watcher events, compile completion, or errors.

## 7. Implementation Phases & Tasks

### Phase 0 – Project Setup
- [x] Create new SwiftUI macOS app target `AdapterStudio` with separate bundle ID and Info.plist.
- [x] Configure signing, entitlements (if draft compilation requires background tasks), and ensure target builds.
- [x] Establish shared code groups (`AdapterStudio/App`, `AdapterStudio/Services`, etc.) with distinct Provider and Compare subfolders.

### Phase 1 – Core Infrastructure
- [x] Implement `AdapterProvider` protocol with:
  - [x] manual file picker (using `NSOpenPanel`).
  - [x] default directory path management and validation.
- [x] Build `ModelCompareEngine`:
  - [x] instantiate base model session (`SystemLanguageModel.default` or `useCase`).
  - [x] instantiate adapter session lazily after provider returns `URL`.
  - [x] expose `async` API `submit(prompt:)` returning structured responses including timing.
  - [x] support streaming via `AsyncStream`.
- [x] Integrate `OSLog` logging for lifecycle events.

### Phase 2 – UI & Interaction
- [x] Construct `CompareWorkbenchView` with shared prompt input and run button.
- [x] Wire `CompareViewModel` to `ModelCompareEngine`, handling streaming updates and cancellation.
- [x] Implement `SessionColumnView` to render incremental tokens, progress bar, metadata, and error states.
- [x] Show adapter status (loaded version, file timestamp) in UI header.
- [x] Add toast/alert system for load failures or compatibility issues.

### Phase 3 – History & Persistence *(Deferred until post-MVP)*
- [ ] Design `Transcript` model (prompt, base text, adapter text, metrics, adapter metadata).
- [ ] Implement `TranscriptStore` (JSON file under `Application Support/AdapterStudio`).
- [ ] Create `HistoryViewModel` + `HistorySidebarView` to list transcripts, with selection displaying detail overlay.
- [ ] Support exporting transcripts as Markdown/JSON for sharing.

### Phase 4 – Advanced Features (Optional Stretch, Deferred)
- [ ] Token diff highlighting – compute diff using `CollectionDifference`.
- [ ] Batch prompt runner – load `.jsonl` dataset and iterate prompts automatically, summarizing metrics.
- [ ] Draft model compilation toggle using `BackgroundTasks` to call `adapter.compile()` asynchronously.
- [ ] Telemetry dashboard (charts for latency over time) using `Charts` framework.
- [ ] Quick compare shortcuts (hotkeys, command palette).

## 8. Tooling & Automation
- [ ] (Future) Add a dedicated scheme `AdapterStudio` once core scaffolding is ready.
- [ ] Create a fastlane or shell script to package the app with latest adapters for distribution to teammates.
- [ ] Add linting rules to prevent accidental imports from production app targets where not intended.
- [ ] Optional: Pre-commit hook verifying no `.fmadapter` files are committed.

## 9. Documentation & Onboarding
- [ ] README section or `docs/AdapterStudio.md` covering:
  - [ ] Setup steps (target selection, folder structure).
  - [ ] How to drop adapters for hot reload.
  - [ ] Known limitations and entitlement notes.
- [ ] Screenshots or screen recordings once UI stabilizes.

## 10. Risks & Mitigations
- [ ] **Foundation Models availability** – ensure running machine has macOS version with supported models; provide fallback messaging.
- [ ] **Large file handling** – guard memory usage when loading adapters; consider streaming load or progress indication.
- [ ] **API evolution** – wrap Foundation Models APIs (still beta) behind lightweight abstraction for future-proofing.
- [ ] **File watcher reliability** – test with network drives vs. local disk; provide manual reload button as backup.

## 11. Open Questions
- [ ] Should Adapter Studio share code (models/services) with production app via Swift Package, or remain isolated to avoid coupling?
- [ ] Do we need entitlements or special provisioning for draft compilation on macOS builds distributed internally?
- [ ] Is there a need for multi-language prompt datasets or evaluation metrics beyond simple diffing?
- [ ] Should Adapter Studio support remote (server-hosted) adapters in future—if so, define manifest schema now?

---

**Next Step Checklist**
- [ ] Align with team on macOS-only scope and directory conventions.
- [ ] Confirm adapter directory location and manifest structure expectations.
- [ ] Focus Phase 1 efforts on `ModelCompareEngine` scaffolding and streaming pipeline.

## 12. Adapter CLI Plan

### Goals
- [x] Provide a scripted workflow for training, evaluating, and exporting adapters without relying on notebooks.
- [x] Match the ergonomics of `mlx-swift-examples` command-line tools (discoverable subcommands, grouped options).
- [x] Keep the CLI portable across macOS and Linux training environments with no extra dependencies beyond the toolkit.

### Architecture Overview
- [x] Create an `adapter_cli` Python package with `__main__.py` and an `adapter-studio` console entry point.
- [x] Use `argparse` with subparsers; share option groups for model assets, logging verbosity, and config hydration.
- [ ] Initial subcommands delegate to existing modules:
  - [ ] `generate` → wraps `examples.generate` for prompt smoke tests.
  - [ ] `train-adapter` → orchestrates `examples.train_adapter`.
  - [ ] `train-draft` → calls `examples.train_draft_model` (optional).
  - [ ] `export` → wraps `export.export_fmadapter`.
- [ ] Reserve future subcommands for asset bundling and dataset validation.

### Integration Notes
- [ ] Refactor sample scripts to expose reusable `run_*` functions that accept explicit parameters (no reliance on `argparse.Namespace`).
- [ ] Preserve streaming stdout/stderr so progress bars and loss metrics surface naturally.
- [ ] Support prompt file resolution (`@/path/prompt.txt`) and TOML/JSON config preload (`--config training.toml`).
- [ ] Validate toolkit asset directories and system-model versions before long-running jobs start.

### Testing & DX
- [x] Clean, professional help output with banner display on all commands.
- [ ] Add smoke tests covering each subcommand with minimal fixtures.
- [x] Implement discoverable subcommands with clear help text.
- [ ] Emit friendly error messages for missing assets, Python version mismatches, or incompatible checkpoints.

---

### Adapter CLI Implementation Progress

#### Phase 0 – Bootstrap (Completed)
- [x] Created `adapter_cli/` Python package in `Adapter Studio/` folder
- [x] Implemented `adapter_cli/__init__.py`, `adapter_cli/__main__.py`
- [x] Wired console entry point `adapter-studio` in `pyproject.toml`
- [x] Package installable via `pip install -e .` with `--break-system-packages` flag
- [x] Created `adapter_cli/banner.py` with ASCII art banner (BLOCK style)
- [x] Created `adapter_cli/config.py` for toolkit path persistence (`~/.adapter-studio/config.json`)
- [x] Created `adapter_cli/validator.py` for toolkit integrity validation
- [x] Created `adapter_cli/discovery.py` for auto-discovery in common locations
- [x] Custom argparse formatter for clean, professional help output
- [x] Graceful error handling (KeyboardInterrupt, EOFError)

#### Phase 1 – Onboarding (Completed)
- [x] Implemented `adapter_cli/commands/init.py` subcommand
- [x] Auto-discovery of toolkit in `~/Downloads/`, `~/adapter-toolkit`, `/opt/adapter-toolkit`
- [x] Fallback to manual path entry with validation
- [x] Config persistence across runs
- [x] Professional output without emojis or brackets

#### Phase 2 – Core Subcommands (In Progress)
1. **Refactor Existing Scripts**
   - [ ] Extract callable helpers from `examples/generate.py`, `examples/train_adapter.py`, `examples/train_draft_model.py`, and `export/export_fmadapter.py`.
   - [ ] Ensure helpers return structured results (metrics, output file paths) for future automation.
2. **Implement Subcommands**
   - [ ] `generate` → wraps toolkit's text generation
   - [ ] `train-adapter` → orchestrates adapter training
   - [ ] `train-draft` → trains draft model
   - [ ] `export` → exports to `.fmadapter` format
   - [ ] Map parsed arguments to refactored helpers; handle asset validation.
   - [ ] Forward streaming logs and catch exceptions to provide concise failure summaries with optional verbose traces.

#### Phase 3 – Quality Gates (Future)
- [ ] Write smoke tests covering each subcommand with sample data.
- [ ] Emit friendly error messages for missing assets, Python version mismatches.
- [ ] Add optional `--verbose` flag for detailed output.

#### Phase 4 – Future Enhancements (Backlog)
- [ ] Add `bundle` subcommand for packaging adapters.
- [ ] Add `validate-data` for dataset linting.
- [ ] Add batch evaluation runners for regression measurement.

