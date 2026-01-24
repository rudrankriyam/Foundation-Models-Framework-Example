# Plan: App Intents Deep Linking (Option B)

## Phase 1: Routing state foundation
- Add per-tab navigation paths to `NavigationCoordinator`.
- Add helper navigation APIs for tab + section targeting.
- Keep UI wiring unchanged in this phase to isolate routing state changes.
- Build the project and commit.

## Phase 2: SwiftUI path wiring
- Convert root `NavigationStack` usage to `NavigationStack(path:)` with typed paths.
- Inject `NavigationCoordinator` into the environment for shared routing.
- Update Chat presentation to use shared route state for intent-driven entry.
- Build the project and commit.

## Phase 3: App Intents integration
- Update existing App Intent(s) to use the new deep-link APIs.
- Add intent(s) for opening specific sections (example/tool/schema/language).
- Refresh App Shortcuts to include new intents.
- Build the project and commit.
