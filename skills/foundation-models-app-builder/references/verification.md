# Verification

Use this reference before finishing Foundation Models app changes.

## Build Commands

```bash
xcodebuild -project FoundationLab.xcodeproj -scheme "Foundation Lab" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
cd FoundationLabCore && swift test
```

For another app, replace the project, scheme, destination, and package path with the target app's equivalents.

## Manual Checks

- Apple Intelligence unavailable
- Apple Intelligence disabled
- model still downloading or not ready
- denied permissions
- cancellation during streaming
- retry after decoding failure
- long conversation near the context limit
- unsupported language or locale
- guardrail refusal
- SwiftUI state updates on the main actor

## Structured Generation Checks

- Static output uses `@Generable` instead of runtime schemas.
- Dynamic schema output uses explicit dependencies for references.
- Optional fields are intentionally optional.
- Retry prompts lower temperature and narrow constraints.
- Decoding failures become user-facing recovery.

## Tool Checks

- Read-only tools can execute directly.
- Write tools require user confirmation.
- Tool arguments are bounded and validated.
- Tool output avoids leaking unnecessary private data back to the model.
- Permission denial is a normal path.

## PR Summary Template

```markdown
## Summary
- added/changed the Foundation Models feature
- included availability, permission, and error handling
- kept shared model orchestration reusable where appropriate

## Verification
- `xcodebuild ...`
- `swift test`
- manual: unavailable model, denied permission, cancellation, retry
```
