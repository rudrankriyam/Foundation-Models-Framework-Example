# Inline Voice Mode - Detailed Implementation Plan

## Overview

Transform the current modal voice mode into an inline voice experience similar to ChatGPT's new inline voice mode (Nov 2025).

**Reference:** [TechCrunch: ChatGPT's voice mode is no longer a separate interface](https://techcrunch.com/2025/11/25/chatgpts-voice-mode-is-no-longer-a-separate-interface/)

---

## Step 1: Voice State Enum (Current Focus)

### Smallest Possible Step

Add ONLY the state enum to ChatViewModel - no methods yet.

```swift
// In ViewModels/ChatViewModel.swift

/// Voice mode state machine
enum VoiceState: Equatable {
    case idle
    case loading
    case listening(partialText: String)
    case processing(response: String)
    case speaking(response: String)

    var isActive: Bool {
        switch self {
        case .idle: return false
        default: return true
        }
    }
}

/// In ChatViewModel class:
@MainActor var voiceState: VoiceState = .idle
@MainActor var voicePartialText: String = ""
```

**Why enum instead of booleans:**
- Single source of truth
- Impossible invalid states (e.g., loading + listening)
- Easy to add new states
- Pattern matches existing `SpeechRecognitionStateMachine`

---

## User Experience Flow (Full State Diagram)

```
┌─────────────────────────────────────────────────────────────────┐
│                      Voice Button States                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  [idle] ───tap──→ [loading] ──done──→ [listening("")]          │
│       ▲                     │cancel            │                │
│       │                     ▼                  │tap             │
│       └──────────────── [listening] ←──────────┘                │
│                              │                                   │
│                              │tap End                            │
│                              ▼                                   │
│                      [processing]                                │
│                              │                                   │
│                              ▼                                   │
│                      [speaking]                                   │
│                              │                                   │
│                              ▼                                   │
│                           [idle]                                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### State Descriptions

| State | UI | Actions |
|-------|-----|---------|
| **idle** | Microphone button | Tap → start loading |
| **loading** | ProgressView + "Cancel" | Pre-warming model & STT, or Cancel → idle |
| **listening("")** | "End" button | Show partial text, tap End → processing |
| **processing** | Thinking indicator | AI generating response |
| **speaking("")** | Text visible | TTS playing response |

---

## Detailed UX Requirements

### 1. Pre-warm on Voice Button Tap

**When user taps microphone:**
1. Dismiss keyboard (if focused)
2. Start pre-warming the Foundation Models session
3. Show loading state

**Pre-warm API (from FoundationModels):**
```swift
// Basic prewarming
session.prewarm()

// With prompt prefix for better caching
session.prewarm(promptPrefix: Prompt(instructions))
```

**Existing code reference:**
- `Foundation Lab/Voice/Services/InferenceService.swift` - has `session.prewarm()` call
- `Foundation Lab/Voice/VoiceViewModel.swift:176-192` - `prewarmAndGreet()` method

### 2. Loading State (Progress + Cancel)

**UI Elements:**
- **Indeterminate ProgressView** (spinner)
- "Cancel" button (same position as voice button)

**Behavior:**
- Show while pre-warming model AND loading speech-to-text
- Tapping "Cancel":
  - Cancels pre-warm task
  - Dismisses keyboard (if opened)
  - Returns to Idle state

**Implementation:**
```swift
@MainActor var isVoiceLoading: Bool = false
@MainActor var voiceLoadingProgress: Double = 0.0  // Optional: for determinate progress

func startVoiceLoading() async {
    // Dismiss keyboard
    isTextFieldFocused = false

    // Start loading
    isVoiceLoading = true

    // Pre-warm model (concurrent with STT initialization)
    await withTaskGroup(of: Void.self) { group in
        group.addTask {
            await self.prewarmModel()
        }
        group.addTask {
            await self.initializeSpeechRecognizer()
        }
    }

    isVoiceLoading = false
    isListening = true  // Ready for input
}

func cancelVoiceLoading() {
    isVoiceLoading = false
    isListening = false
    isTextFieldFocused = false  // Ensure keyboard is dismissed
}
```

### 3. Listening State (End Button)

**When ready to listen:**
- Show "End" button
- Optionally show live partial transcript in input area
- User can tap text field to switch to text input

### 4. Navigation Title Change

**When voice mode is active:**
- Change navigation title from "Chat" to "Voice"
- When voice ends, change back to "Chat"

**Implementation in ChatView:**
```swift
.navigationTitle(viewModel.isVoiceModeActive ? "Voice" : "Chat")
```

### 5. Message Flow

```
User speaks
    ↓
Speech recognized (partial updates)
    ↓
User taps "End"
    ↓
Add USER message to transcript
    ↓
AI generates response
    ↓
Add ASSISTANT message to transcript
    ↓
Play TTS audio for response
```

---

## Files to Modify

### 1. `ViewModels/ChatViewModel.swift`

**Add voice state:**
```swift
// Voice mode state
@MainActor var isVoiceModeActive: Bool = false
@MainActor var isVoiceLoading: Bool = false
@MainActor var isListening: Bool = false
@MainActor var voicePartialText: String = ""

// Voice methods
func startVoiceMode() async
func cancelVoiceMode()
func stopVoiceModeAndSend() async
func handleVoicePartialUpdate(_ text: String)
```

**Add services:**
- `SpeechRecognizer` (reuse from Voice/VoiceViewModel)
- `SpeechSynthesizer` (reuse `shared`)
- `PermissionManager`

**Modify message sending:**
- Add `sendVoiceMessage(_ text: String)` method that:
  1. Adds user message to transcript
  2. Calls AI for response
  3. Plays TTS
  4. Adds assistant message to transcript

### 2. `Views/Components/ChatInputView.swift`

**Add voice state parameter:**
```swift
@Binding var isVoiceModeActive: Bool
@Binding var isVoiceLoading: Bool
@Binding var isListening: Bool
@Binding var voicePartialText: String
```

**Voice button behavior (lines 35-47):**
```swift
if viewModel.isVoiceLoading {
    // Loading state: Progress bar + Cancel
    ProgressView()
    Button("Cancel") {
        viewModel.cancelVoiceMode()
    }
} else if viewModel.isVoiceModeActive && viewModel.isListening {
    // Listening state: End button
    Button("End") {
        await viewModel.stopVoiceModeAndSend()
    }
} else if messageText.isEmpty {
    // Idle state: Microphone
    Button(action: {
        await viewModel.startVoiceMode()
    }) {
        Image(systemName: "waveform")
    }
} else {
    // Text mode: Send button
    Button(action: sendMessage) { ... }
}
```

### 3. `Views/Chat/ChatView.swift`

**Remove modal sheet:**
- Remove `.sheet(isPresented: $showVoiceSheet)` (lines 98-103)
- Remove `showVoiceSheet` state variable

**Pass voice state to ChatInputView:**
```swift
ChatInputView(
    messageText: $messageText,
    isTextFieldFocused: $isTextFieldFocused,
    isVoiceModeActive: $viewModel.isVoiceModeActive,
    isVoiceLoading: $viewModel.isVoiceLoading,
    isListening: $viewModel.isListening,
    voicePartialText: $viewModel.voicePartialText,
    onVoiceTap: { /* No longer needed */ }
)
```

**Dynamic navigation title:**
```swift
.navigationTitle(viewModel.isVoiceModeActive ? "Voice" : "Chat")
```

### 4. `Views/Components/MessageBubbleView.swift` (Optional)

May need styling adjustments for voice messages if distinguishable from text messages.

---

## Existing Code to Reuse

| Component | Location | Reuse Strategy |
|-----------|----------|----------------|
| `SpeechRecognizer` | `Voice/Services/` | Copy or import |
| `SpeechSynthesizer.shared` | `Voice/Services/` | Use singleton |
| `PermissionManager` | `Voice/Services/` | Share instance |
| `SpeechRecognitionStateMachine` | `Voice/State/` | Reference patterns |
| `prewarm(promptPrefix:)` | `FoundationModels` | Call on session |

---

## Implementation Order

### Phase 1: State & Services
1. Add voice state properties to `ChatViewModel`
2. Add/create `SpeechRecognizer` instance
3. Integrate `PermissionManager` check
4. Implement `startVoiceMode()` with pre-warm

### Phase 2: Loading UI
1. Add loading state to `ChatInputView`
2. Implement progress bar + Cancel button
3. Handle Cancel action (dismiss keyboard)
4. Connect `isVoiceLoading` binding

### Phase 3: Listening UI
1. Add "End" button state
2. Add `voicePartialText` display
3. Implement text field focus switch

### Phase 4: Transcript Integration
1. Implement `sendVoiceMessage()`
2. Connect to `session.respond()`
3. Add messages to transcript
4. Add TTS playback

### Phase 5: Navigation & Cleanup
1. Dynamic navigation title
2. Remove modal sheet code
3. Test full flow

---

## Testing Checklist

- [ ] Voice permissions requested correctly
- [ ] Tap microphone → progress bar + Cancel appears
- [ ] Tap Cancel → keyboard dismissed, returns to idle
- [ ] Loading completes → "End" button appears
- [ ] Tap End → message added to transcript
- [ ] AI response appears in transcript
- [ ] TTS plays for AI response
- [ ] Navigation title changes to "Voice" and back
- [ ] Can switch to text input during voice mode
- [ ] Chat history preserved

---

## Rollback Strategy

Keep copies of:
- `VoiceView.swift` (can restore as "Separate Mode" option)
- Original `ChatView.swift` sheet code
- Original `ChatInputView.swift` voice button

---

## References

- **Foundation Models pre-warm API:** `session.prewarm(promptPrefix: Prompt?)`
- **ChatGPT inline voice mode:** https://techcrunch.com/2025/11/25/chatgpts-voice-mode-is-no-longer-a-separate-interface/
- **Existing pre-warm example:** `Foundation Lab/Playgrounds/02_GettingStartedWithSessions/11_BasicPrewarming.swift`
- **VoiceViewModel pre-warm:** `Foundation Lab/Voice/VoiceViewModel.swift:176-192`
