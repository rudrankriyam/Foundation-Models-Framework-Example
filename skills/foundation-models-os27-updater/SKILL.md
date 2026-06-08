---
name: foundation-models-os27-updater
description: Upgrade any Apple Foundation Models Swift app or package from OS 26-era APIs to OS 27 and Xcode 27 APIs. Use when modernizing LanguageModelSession code, GenerationOptions, tool calling, context-window handling, image input, Private Cloud Compute, shared LanguageModel runtimes, reasoning controls, transcript handling, custom executors, feedback, availability gates, docs, examples, tests, or build settings.
---

# Foundation Models OS 27 Updater

Use this skill to migrate a Foundation Models project from the OS 26 API surface to OS 27. The target may be an app, Swift package, sample, CLI, framework, tutorial repo, or documentation repo. Do not assume it is Foundation Lab or has this repository's structure.

The goal is not to sprinkle OS 27 names into code. The goal is to make the project take real advantage of OS 27 where it helps: better runtime selection, context management, tool policy, multimodal input, transcript handling, observability, and honest availability behavior.

## Operating Principles

- Start from the target project, not from a generic example.
- Inspect the installed Xcode 27 SDK before claiming an API exists.
- Preserve unrelated user changes.
- Prefer small typed adapters over one giant compatibility layer.
- Keep OS 27 features discoverable without forcing demos that do not fit the product.
- Make availability, entitlement, service eligibility, quota, and platform gates visible in code and docs.
- Compile with Xcode 27 even if runtime smoke tests require OS 27 hardware.

## First Pass: Understand The Project

Run a fast audit before editing:

```bash
git status --short --branch
rg -n "import FoundationModels|LanguageModelSession|SystemLanguageModel|GenerationOptions|Prompt|Transcript|Tool|@Generable|DynamicGenerationSchema|GeneratedContent|Feedback|Attachment|ImageReference|tokenCount|contextSize" .
rg -n "IPHONEOS_DEPLOYMENT_TARGET|MACOSX_DEPLOYMENT_TARGET|VISIONOS_DEPLOYMENT_TARGET|WATCHOS_DEPLOYMENT_TARGET|platforms:|Package.swift|swift-tools-version" .
find . -maxdepth 3 \( -name "*.xcodeproj" -o -name "*.xcworkspace" -o -name "Package.swift" \)
```

Then classify the work:

- **App**: update user-facing flows, availability UI, build settings, and simulator/device verification.
- **Swift package/framework**: expose OS 27 APIs through reusable types; avoid app-specific UI assumptions.
- **Sample/tutorial**: add focused examples and comments that teach migration choices.
- **CLI/tooling**: expose flags for runtime, context, tool mode, reasoning, and diagnostics where useful.
- **Docs-only repo**: update examples, platform requirements, deprecation notes, and verification snippets.

## SDK Inspection

Use the active Xcode 27 SDK as the source of truth. Adapt paths for the user's Xcode:

```bash
export DEVELOPER_DIR=/Users/rudrank/Downloads/Xcode-beta.app/Contents/Developer
xcrun --show-sdk-path --sdk iphoneos
xcrun --show-sdk-path --sdk macosx
```

Search FoundationModels interfaces:

```bash
SDK="$(xcrun --show-sdk-path --sdk iphoneos)"
rg -n "final public class PrivateCloudComputeLanguageModel|protocol LanguageModel|contextSize|toolCallingMode|samplingMode|ImageAttachment|ImageReference|reasoning|Transcript|Feedback|LanguageModelExecutor" "$SDK/System/Library/Frameworks/FoundationModels.framework"
```

If the project has its own generated interface notes, refresh or verify them from SDK interfaces. Do not let stale docs outrank the local SDK.

## Migration Decision

Choose one path explicitly:

- **OS 27-only**: raise deployment targets and package platforms, simplify code to OS 27 APIs, and remove noisy OS 26 compatibility only where the user wants that.
- **OS 26 + OS 27 compatible**: keep the existing OS 26 path and isolate new symbols behind `#available` wrappers or separate OS 27-only files.
- **Compile-only OS 27 support**: update source to build with Xcode 27 while noting runtime features that cannot be exercised on the current host.

For packages, prefer public wrappers that compile for the declared platform matrix. Avoid leaking OS 27-only symbols into APIs that must be consumed from OS 26 without availability annotations.

## API Migration Checklist

### GenerationOptions

Update renamed or expanded options first because they break builds quickly:

- Replace deprecated sampling spelling with `samplingMode` when the SDK exposes it.
- Add `toolCallingMode` only where behavior should change.
- Keep temperature, max tokens, and sampling controls near existing generation configuration.
- Ensure docs and CLI flags use the same names as the code.

### Model Availability

Keep availability checks close to features:

```swift
let model = SystemLanguageModel.default
switch model.availability {
case .available:
    break
case .unavailable(let reason):
    // Render or return a clear unavailable state.
}
```

For OS 27 additions, combine Foundation Models availability with platform checks:

```swift
if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
    let contextSize = SystemLanguageModel.default.contextSize
} else {
    // Existing OS 26 fallback.
}
```

### Shared LanguageModel Runtime

If the project has multiple model backends or wants PCC, introduce a small runtime abstraction:

- `.system` for `SystemLanguageModel.default`.
- `.privateCloudCompute` for `PrivateCloudComputeLanguageModel()`.
- `.automatic` or `.pccWhenAvailable` only if the app has a clear fallback policy.

Avoid re-resolving adaptive runtime mid-request. Resolve once, create the session from that model, and use the same resolved runtime for diagnostics and token/context accounting.

### Private Cloud Compute

Add PCC only when it serves the product or sample. PCC code should report:

- availability
- unavailable reason
- quota status and reset date when available
- context size, which may be async and throwing
- supported languages if exposed by the SDK
- network, service, quota, and eligibility failures

Do not present PCC as guaranteed. Treat it as OS/service/entitlement/network gated.

### Context Window And Token Budget

Replace hardcoded context assumptions with runtime information:

- `SystemLanguageModel.contextSize` for local model budget when available.
- PCC context size through the PCC API when available.
- `tokenCount(for:)` or existing project token accounting for prompt pressure.
- Summarization, truncation, or refusal when a prompt exceeds budget.

Good app behavior:

- show or log budget in diagnostics
- compact long conversation history before overflow
- catch context-size-exceeded errors and provide a recovery path

### Tool Calling Mode

Map product modes to explicit tool policy:

- `.allowed`: normal assistant mode where tools are optional.
- `.required`: workflows that must call a tool to be useful, such as fetching current data.
- `.disallowed`: drafting, summarization, or privacy-sensitive flows where tools should not run.

Do not rely on prompts alone to prevent tool use when the SDK exposes a policy option.

### Image Input

When adding image support:

- prefer typed prompt/attachment APIs over stringly image descriptions
- keep text-only fallbacks
- gate UIKit/AppKit convenience initializers by platform
- handle missing image permission or unsupported image content cleanly
- update examples to show the actual image path or picker behavior

### Dynamic Instructions And Profiles

If the app has user-selectable personas or modes, move them into typed configuration:

- model/runtime
- instructions
- generation options
- tool policy
- reasoning level
- language/locale
- safety or privacy mode

Keep reset/default behavior obvious so users can return to a known profile.

### Reasoning Controls

Expose reasoning controls only when users can understand the tradeoff:

- use small labels like light, balanced, deep, or project-specific names
- explain cost/latency/quality implications in docs or settings text
- avoid claiming better answers without measuring or demonstrating it

### Transcript Handling

Update transcript parsing, rendering, replay, export, and logging for new segment types:

- text segments
- tool calls and tool results
- reasoning segments
- attachments
- custom or unknown segments
- feedback-related entries if present

Make switches exhaustive. If preserving transcripts matters, store unknown/custom segments instead of dropping them.

### Custom Executors

If the project implements a custom model executor:

- update method signatures to the Xcode 27 shape
- keep streaming channel behavior cancellable
- test the executor with a fake response path
- document whether the executor supports tools, images, reasoning, and structured output

### Feedback And Observability

Use OS 27 feedback/transcript surfaces to improve debugging:

- attach feedback to the relevant transcript/session when supported
- record runtime, availability, context size, token count, tool mode, and error category
- avoid logging private prompt or Health/Contacts/Calendar data unless the app already has consented diagnostics

## Code Organization Patterns

For apps:

```text
Models/
  FoundationModelRuntime.swift
  FoundationModelAvailabilityState.swift
Services/
  FoundationModelClient.swift
  ContextBudgetManager.swift
Views/
  ModelUnavailableView.swift
  RuntimeDiagnosticsView.swift
```

For packages:

```text
Sources/PackageName/
  Runtime/
  Context/
  Tools/
  Transcripts/
Tests/PackageNameTests/
```

Keep SwiftUI views thin. Put Foundation Models orchestration in services/use cases so CLI, widgets, App Intents, and tests can reuse it.

## Documentation Updates

Update docs when code behavior changes:

- minimum Xcode version
- deployment targets and platform matrix
- Apple Intelligence requirements
- PCC entitlement or service eligibility requirements
- OS 26 fallback behavior, if preserved
- OS 27-only examples
- build command using `DEVELOPER_DIR`
- runtime testing limitations on non-OS 27 hosts

Avoid vague phrasing like "uses latest APIs" without naming what changed.

## Verification Matrix

Choose the narrowest checks that cover the change:

```bash
git diff --check
DEVELOPER_DIR=/path/to/Xcode-beta.app/Contents/Developer swift build
DEVELOPER_DIR=/path/to/Xcode-beta.app/Contents/Developer swift test
DEVELOPER_DIR=/path/to/Xcode-beta.app/Contents/Developer xcodebuild -project App.xcodeproj -scheme "App" -destination "platform=iOS Simulator,name=iPhone 17 Pro" -derivedDataPath ./build-xcode27 build
```

Also verify manually when possible:

- model availability renders correctly when unavailable
- system runtime can generate a simple response
- PCC unavailable state is graceful
- context budget displays or logs correctly
- tool mode changes behavior
- image prompt path works or falls back cleanly
- transcript export/replay does not crash on new segments

If runtime smoke tests require OS 27 hardware or entitlement approval, say that plainly in the final report and PR body.

## PR Expectations

A good migration PR should include:

- short summary of which OS 27 surfaces were adopted
- whether OS 26 compatibility was kept or dropped
- files touched by category: build settings, runtime code, UI/examples, docs/tests
- validation commands and results
- runtime limitations that could not be tested locally
- follow-up work only when it is truly outside the current safe scope

Do not claim a feature is live just because it compiles. For OS/service-gated APIs like PCC, distinguish compile support, availability probing, entitlement status, and real runtime success.
