# Foundation Models Framework Example

A practical iOS app demonstrating Apple's Foundation Models framework with various examples of on-device AI capabilities.

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

## Getting Started

1. Clone the repository
2. Open `FMF.xcodeproj` in Xcode
3. Ensure you have a device with Apple Intelligence enabled
4. Build and run the project
5. Explore the different AI capabilities through the example buttons

## License

This project is licensed under the MIT License - see the LICENSE file for details.