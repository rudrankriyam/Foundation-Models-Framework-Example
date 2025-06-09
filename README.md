# Foundation Models Framework Example

A production-ready iOS app demonstrating Apple's Foundation Models framework with clean architecture, MVVM pattern, and comprehensive examples of on-device AI capabilities.

## 🏗️ Architecture

This project follows modern iOS development best practices with a layered, modular architecture:

```
FMF/
├── Models/                     # Data models and error handling
│   ├── DataModels.swift       # @Generable structures
│   └── FoundationModelsError.swift # Custom errors
├── Services/                   # Business logic layer
│   └── FoundationModelsService.swift # Core AI service
├── Tools/                      # Custom AI tools
│   ├── WeatherTool.swift      # Weather information tool
│   └── BreadDatabaseTool.swift # Recipe search tool
├── ViewModels/                 # MVVM presentation logic
│   └── ContentViewModel.swift # Main view model
├── Views/
│   ├── Components/            # Reusable UI components
│   │   ├── ExampleButton.swift
│   │   └── ResponseDisplayView.swift
│   └── ContentView.swift      # Main view
└── README.md
```

## 🎯 Engineering Principles

- **MVVM Architecture**: Clear separation between UI, business logic, and data
- **Dependency Injection**: Service layer properly injected into ViewModels
- **Single Responsibility**: Each component has one clear purpose
- **Reactive UI**: Using `@Observable` for real-time updates
- **Error Handling**: Comprehensive error management throughout the stack
- **Reusability**: Components designed for reuse across the app
- **Type Safety**: Strong typing with Foundation Models protocols

## Requirements

- iOS 26.0+ or macOS 26.0+
- Apple Intelligence enabled
- Compatible Apple device with Apple Silicon

## Features

### 🤖 Core AI Capabilities
- **Basic Chat**: Simple conversational interactions
- **Structured Data Generation**: Type-safe data generation with `@Generable`
- **Generation Guides**: Constrained outputs with `@Guide` annotations
- **Streaming Responses**: Real-time response streaming
- **Tool Calling**: Custom tools for extended functionality
- **Model Availability**: System capability checking

### 🎨 Creative Features
- **Creative Writing**: Story outline and narrative generation
- **Business Ideas**: Startup concept and business plan generation

### 🛠️ Custom Tools
- **Weather Tool**: Multi-city weather information with simulated data
- **Recipe Database**: Advanced bread recipe search with filtering

## Usage Examples

### Basic Chat
```swift
let service = FoundationModelsService()
let response = try await service.generateResponse(
    prompt: "Suggest a catchy name for a new coffee shop.",
    instructions: "You are a helpful assistant."
)
```

### Structured Data Generation
```swift
let bookInfo = try await service.generateStructuredData(
    prompt: "Suggest a sci-fi book.",
    type: BookRecommendation.self
)
print("Title: \(bookInfo.title)")
print("Author: \(bookInfo.author)")
```

### Tool Calling
```swift
let session = service.createSessionWithTools()
let response = try await session.respond(
    to: Prompt("Is it hotter in Boston or Chicago?")
)
```

### Streaming Responses
```swift
let finalResponse = try await service.streamResponse(
    prompt: "Write a short poem about technology.",
    onPartialUpdate: { partialText in
        print("Partial: \(partialText)")
    }
)
```

## Data Models

The app includes comprehensive `@Generable` data models:

### Book Recommendations
```swift
@Generable
struct BookRecommendation {
    @Guide(description: "The title of the book")
    let title: String
    
    @Guide(description: "The author's name")
    let author: String
    
    @Guide(description: "Genre of the book")
    let genre: Genre
}
```

### Product Reviews
```swift
@Generable
struct ProductReview {
    @Guide(description: "Product name")
    let productName: String
    
    @Guide(description: "Rating from 1 to 5")
    let rating: Int
    
    @Guide(description: "Key pros of the product")
    let pros: [String]
}
```

## Custom Tools

### Weather Tool
Provides weather information with realistic simulation:
- Multi-city weather database
- Temperature, humidity, and wind data
- Fallback to random generation for unknown cities

### Bread Database Tool
Advanced recipe search capabilities:
- Comprehensive recipe database
- Smart search across names, descriptions, and tags
- Difficulty levels and preparation times
- Relevance-based sorting

## Error Handling

Comprehensive error handling with custom error types:

```swift
enum FoundationModelsError: LocalizedError {
    case sessionCreationFailed
    case responseGenerationFailed(String)
    case toolCallFailed(String)
    case streamingFailed(String)
    case modelUnavailable(String)
}
```

## Architecture Benefits

1. **Testability**: Clean separation allows for easy unit testing
2. **Maintainability**: Modular structure makes code easy to maintain
3. **Scalability**: Easy to add new features and tools
4. **Reusability**: Components can be reused across different parts of the app
5. **Type Safety**: Strong typing prevents runtime errors
6. **Performance**: Efficient async/await patterns and proper memory management

## Getting Started

1. Clone the repository
2. Open `FMF.xcodeproj` in Xcode
3. Ensure you have a device with Apple Intelligence enabled
4. Build and run the project
5. Explore the different AI capabilities through the example buttons

## Privacy & Security

- **On-device Processing**: All AI operations happen locally
- **No Data Transmission**: No user data sent to external servers
- **Apple's Privacy Standards**: Built on Apple's privacy-first AI framework

## Contributing

When contributing to this project, please maintain the established architecture:

1. Follow the MVVM pattern
2. Add new data models to `Models/DataModels.swift`
3. Implement new tools in the `Tools/` directory
4. Use the service layer for business logic
5. Create reusable components in `Views/Components/`

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Built with Apple's Foundation Models framework
- Demonstrates modern iOS development practices
- Showcases on-device AI capabilities 