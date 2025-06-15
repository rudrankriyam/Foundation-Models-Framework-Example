# Foundation Models Framework Example

A practical iOS app demonstrating Apple's Foundation Models framework with various examples of on-device AI capabilities.

## Support

Love this project? Check out my books to explore more of AI and iOS development:
- [Exploring AI for iOS Development](https://academy.rudrank.com/product/ai)
- [Exploring AI-Assisted Coding for iOS Development](https://academy.rudrank.com/product/ai-assisted-coding)

## Requirements

- iOS 26.0+ or macOS 26.0+
- Apple Intelligence enabled
- Compatible Apple device with Apple Silicon

## Features

### Core AI Capabilities
- **Basic Chat**: Simple conversational interactions
- **Structured Data Generation**: Type-safe data generation with `@Generable`
- **Generation Guides**: Constrained outputs with `@Guide` annotations
- **Streaming Responses**: Real-time response streaming
- **Tool Calling**: Custom tools for extended functionality
- **Model Availability**: System capability checking

### Creative Features
- **Creative Writing**: Story outline and narrative generation
- **Business Ideas**: Startup concept and business plan generation

### Custom Tools
- **Weather Tool**: Multi-city weather information with simulated data

## Usage Examples

### Basic Chat
```swift
let session = LanguageModelSession()
let response = try await session.respond(
    to: "Suggest a catchy name for a new coffee shop."
)
print(response.content)
```

### Structured Data Generation
```swift
let session = LanguageModelSession()
let bookInfo = try await session.respond(
    to: "Suggest a sci-fi book.",
    generating: BookRecommendation.self
)
print("Title: \(bookInfo.content.title)")
print("Author: \(bookInfo.content.author)")
```

### Tool Calling
```swift
let session = LanguageModelSession(tools: [WeatherTool()])
let response = try await session.respond(
    to: "Is it hotter in New Delhi or Cupertino?"
)
print(response.content)
```

### Streaming Responses
```swift
let session = LanguageModelSession()
let stream = session.streamResponse(to: "Write a short poem about technology.")

for try await partialText in stream {
    print("Partial: \(partialText)")
}
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
