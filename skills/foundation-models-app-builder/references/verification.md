# Verification

Use this reference before finishing Foundation Models app changes.

## Baseline Commands

Run the narrowest useful command:

```bash
xcodebuild -project FoundationLab.xcodeproj -scheme "Foundation Lab" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
cd FoundationLabCore && swift test
```

If a command is unavailable because the installed Xcode, simulator, or macOS version is too old, report that explicitly.

## Manual Checks

For user-facing features, check:

- model unavailable path
- Apple Intelligence disabled path when feasible
- permission denied path
- cancellation during generation or streaming
- retry behavior after an error
- localization impact if strings changed
- app navigation on iPhone and larger layouts

## Code Review Checklist

- Reusable task logic lives in core use cases/providers where appropriate.
- SwiftUI views do not own long prompt orchestration unless intentionally educational.
- App Intents call shared capabilities instead of duplicating app logic.
- Tool outputs are bounded and safe to show to the model.
- Errors become user-facing recovery, not only console logs.
- Streaming updates are main-actor safe and cancellable.
- Structured generation has a fallback for decoding or schema failure.
- Health, contacts, calendar, reminders, location, music, speech, and microphone permissions are handled at the app boundary.

## PR Summary Template

When summarizing changes, include:

- feature or skill surface changed
- files added or touched
- verification command and result
- any environment limitation
