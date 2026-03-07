# Agents.md

This file provides guidance to AI agents when working with code in this repository.

## Project Overview

Foundation Lab is an iOS/macOS app demonstrating Apple's Foundation Models framework (iOS 26.0+/macOS 26.0+). It accompanies the "Exploring Foundation Models" book and showcases:
- Multi-turn chat with streaming responses using `LanguageModelSession`
- 9 system integration tools (Weather, Web Search, Contacts, Calendar, Reminders, Location, Health, Music, Web Metadata)
- Voice interface with speech-to-text (`SpeechRecognitionStateMachine`) and text-to-speech
- RAG chat with document indexing and semantic search (LumoKit/VecturaKit)
- AI-powered Health Dashboard with HealthKit integration via `HealthDataManager`
- Dynamic schema examples for structured data generation using `@Generable` and `DynamicSchemaBuilder`
- Multilingual support (10 languages) via `LanguageService` and `Localizable.xcstrings`

## Build Commands

```bash
# Open in Xcode
open FoundationLab.xcodeproj

# Build from command line
xcodebuild -project FoundationLab.xcodeproj -scheme "Foundation Lab" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Run on specific simulator
xcodebuild -project FoundationLab.xcodeproj -scheme "Foundation Lab" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath ./build test
```

**Requirements:** Xcode 26.0+, iOS 26.0+/macOS 26.0+, Apple Silicon device with Apple Intelligence.

**Dependencies (SPM):**
- `HighlightSwift` - Syntax highlighting
- `FoundationModelsTools` - Foundation Models utilities
- `LiquidGlasKit` - UI styling
- `LumoKit` - RAG document indexing and retrieval
- `VecturaKit` - Vector search backend

## Architecture

**Pattern:** MVVM with SwiftUI using modern Swift 6 concurrency (`@MainActor`, `Sendable`).

### Core Components

#### LanguageModelSession
The main entry point for Foundation Models interactions:
```swift
let session = LanguageModelSession()
let response = try await session.respond(to: "Hello")
let stream = session.streamResponse(to: "Write a story")
let structured = try await session.respond(to: "Suggest a book", generating: BookRecommendation.self)
```

#### ViewModels (`ViewModels/`)

| ViewModel | Purpose |
|-----------|---------|
| `ChatViewModel.swift` | Multi-turn chat with sliding window context management, streaming responses |
| `VoiceViewModel.swift` | Voice input/output state machine, permission handling |
| `HealthChatViewModel.swift` | Health-specific chat with HealthKit tool integration |
| `DynamicSchemaViewModel.swift` | Dynamic schema builder state management |
| `RAGChatViewModel.swift` | RAG chat with document indexing and retrieval |

All ViewModels use `@Observable` macro and `@MainActor` annotation.

#### Tools (`Views/Tools/` and `Health/Tools/`)

Tools implement a custom `Tool` protocol. Files follow `*Tool.swift` naming:
- `WeatherTool.swift` - OpenMeteo API, no API key required
- `Search1WebSearchTool.swift` - Search1API keyless web search
- `ContactsTool.swift` - System contacts search
- `CalendarTool.swift` - Event creation/management with `EventKit`
- `RemindersTool.swift` - AI-assisted reminder creation
- `LocationTool.swift` - Core Location with geocoding
- `HealthDataTool.swift` - HealthKit queries
- `MusicTool.swift` - Apple Music catalog search
- `WebMetadataTool.swift` - URL metadata extraction

#### Voice Module (`Voice/`)

```
Voice/
├── VoiceView.swift              # Main voice interface UI
├── VoiceViewModel.swift         # State machine for voice interactions
├── Services/
│   ├── InferenceService.swift   # Speech recognition and synthesis
│   └── PermissionManager.swift  # Handles microphone/speech permissions
└── State/
    └── SpeechRecognitionStateMachine.swift  # Recognition state transitions
```

#### Health Module (`Health/`)

```
Health/
├── Models/                      # Health-specific @Generable models
├── Tools/
│   └── HealthDataTool.swift     # HealthKit integration tool
├── ViewModels/
│   └── HealthChatViewModel.swift # Health chat with predictive analytics
└── Views/
    ├── HealthDashboardView.swift     # AI-powered health insights
    ├── HealthChatView.swift          # Health-focused chat interface
    └── Components/                    # Health-specific UI components
```

#### Dynamic Schemas (`Views/Examples/DynamicSchemas/`)

```
DynamicSchemas/
├── SchemaExamplesView.swift      # Schema example selection
├── BasicSchemaView.swift         # Simple @Generable examples
├── ArraySchemaView.swift         # Collection handling
├── EnumSchemaView.swift          # Union types and enums
├── NestedSchemaView.swift        # Nested object structures
├── ReferencedSchemaView.swift    # Schema references
├── FormBuilderView.swift         # Multi-step form generation
├── InvoiceProcessingView.swift   # Complex document parsing
└── ErrorHandlingSchemaView.swift # Schema error patterns
```

#### Examples (`Views/Examples/`)

Examples demonstrate framework capabilities with `ExampleViewBase`:
- `BasicChatView.swift` - One-shot prompts
- `JournalingView.swift` - Prompts and reflective summaries
- `CreativeWritingView.swift` - Creative generation
- `StructuredGenerationView.swift` - Type-safe generation
- `StreamingView.swift` - Real-time streaming
- `GenerationGuidesView.swift` - Constrained outputs with `@Guide`
- `GenerationOptionsView.swift` - Temperature, tokens, fitness
- `HealthExampleView.swift` - Health dashboard example
- `RAGChatView.swift` - Retrieval-augmented chat with documents

### Navigation Architecture

```
FoundationLabApp.swift
  └── AdaptiveNavigationView
        ├── SidebarView (iPad/Mac)
        │     └── TabSelection enum: examples, tools, schemas, languages, settings
        └── ContentView
              ├── ChatView (tab)
              ├── ToolsView (tab)
              ├── ExamplesView (tab)
              └── SettingsView (tab)
```

- `NavigationCoordinator.shared` - Singleton for cross-tab navigation sync
- `TabSelection` enum defines navigation destinations
- `AdaptiveNavigationView` switches between TabView (iPhone) and NavigationSplitView (iPad/Mac)

### Key Patterns

#### Data Models (`Models/`)

```swift
// @Generable for structured generation
@Generable
struct BookRecommendation {
    @Guide(description: "The title of the book")
    let title: String
    let author: String
}

// @Observable for state management
@Observable
final class ChatViewModel {
    var messages: [Message] = []
    var isStreaming: Bool = false
}
```

#### Error Handling (`Models/FoundationModelsError.swift`)

- Custom `FoundationModelsError` enum with `LocalizedError`
- `FoundationModelsErrorHandler` for framework-specific errors
- User-facing errors via `@State showError` in views

#### Services (`Services/`)

- `LanguageService.swift` - `@MainActor @Observable` for language detection/management
- `HealthDataManager.swift` - Shared instance pattern for health data

### Localization (`Localizable.xcstrings`)

- 10 languages: English, German, Spanish, French, Italian, Japanese, Korean, Portuguese (Brazil), Chinese (Simplified), Chinese (Traditional)
- ~450KB file with all translations

### Playground Examples (`BookPlaygrounds/`)

Run directly in Xcode using the `#Playground` directive:
- Chapter 2: 16 examples (Getting Started with Sessions)
- Chapter 3: 5 examples (Generation Options)
- Chapter 8: 9 examples (Basic Tool Use)
- Chapter 13: 7 examples (Languages)

## SwiftLint Configuration (`.swiftlint.yml`)

```yaml
line_length: 140/200
type_body_length: 200/300
file_length: 600/800
identifier_name:
  min_length: 2/1
  max_length: 40/50
type_name:
  max_length: 50/60
function_body_length: 60/100
nesting:
  type_level: 3/5
```

## Key Conventions

- **ViewModels:** Use `@Observable` macro (not `@StateObject`), marked with `@MainActor`
- **Tool files:** Named `*Tool.swift`
- **ViewModel files:** Named `*ViewModel.swift`
- **Navigation:** Use `NavigationStack` with `navigationDestination(for:)`
- **Shared instances:** Singleton pattern with `shared` property
- **Permissions:** Handled automatically via `PermissionManager`
- **Error handling:** Use `FoundationModelsError` + `LocalizedError`
- **State management:** `@State` for local, `@Binding` for parent-child, `@Observable` for ViewModels

## Apple Intelligence Requirements

- Device must support Apple Intelligence
- Enable Apple Intelligence in Settings > Apple Intelligence
- Model availability checked via `ModelAvailabilityChecker`
