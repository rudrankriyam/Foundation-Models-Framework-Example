# FoundationLabCore

`FoundationLabCore` is the first shared package for Foundation Lab.

Its job is narrow:

- define task-oriented capability boundaries
- own shared request and result models
- own domain-level errors
- define provider protocols for concrete adapters

Its job is not to own delivery layers or UI concerns.

## Dependency rules

- `FoundationLabCore` must not import `SwiftUI`, `AppIntents`, or `ArgumentParser`.
- `FoundationLabCore` must not own navigation, tabs, routes, or screen-local state.
- App targets, App Intents adapters, and CLI adapters may depend on `FoundationLabCore`.
- Concrete integrations with Apple frameworks or third-party SDKs belong in adapter packages, not here.

## Initial conventions

- `Capabilities/` contains task-oriented use case protocols and descriptors.
- `Requests/` contains shared request models for core flows.
- `Results/` contains shared result models and execution metadata.
- `Errors/` contains domain-level errors surfaced by capabilities and providers.
- `Providers/` contains abstraction seams that later packages implement.

This package is intentionally small. It creates the seam for later extraction work without moving major user-facing features yet.
