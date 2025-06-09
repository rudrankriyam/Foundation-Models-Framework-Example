# Foundation Models Framework Example

An example iOS app demonstrating the power of Apple's Foundation Models framework for integrating on-device language models into your applications.

## Overview

This project showcases how to use Apple's Foundation Models framework (available in iOS 26.0+ and macOS 26.0+) to create intelligent, privacy-focused applications that leverage on-device language models.

## Requirements

- iOS 26.0+ or macOS 26.0+
- Apple Intelligence enabled
- Compatible Apple device

## Features

- **Basic Chat Sessions**: Simple text-based interactions with language models
- **Structured Data Generation**: Generate typed data objects from natural language prompts
- **Streaming Responses**: Real-time streaming of model responses
- **Tool Calling**: Extend model capabilities with custom tools
- **Generation Guides**: Control and constrain model outputs
- **Transcript Management**: Save and restore conversation history

## Quick Start

### Basic Chat Example

```swift
import FoundationModels

// Create a session with instructions
let session = LanguageModelSession(instructions: "You are a helpful assistant.")

// Generate a response
let prompt = "Suggest a catchy name for a new coffee shop."
let response = try await session.respond(to: prompt)
print(response.content)
```

### Structured Data Generation

```swift
@Generable
struct BookRecommendation {
    @Guide(description: "The title of the book")
    let title: String
    
    @Guide(description: "The author's name")
    let author: String
    
    @Guide(description: "A brief description in 2-3 sentences")
    let description: String
    
    @Guide(description: "Genre of the book")
    let genre: Genre
}

@Generable
enum Genre {
    case fiction
    case nonFiction
    case mystery
    case romance
    case sciFi
}

// Generate structured data
let session = LanguageModelSession()
let bookInfo = try await session.respond(
    to: "Suggest a sci-fi book for someone who loves space exploration.",
    generating: BookRecommendation.self
)
print("Title: \(bookInfo.content.title)")
print("Author: \(bookInfo.content.author)")
```

## Advanced Examples

### Generation Guides and Constraints

```swift
@Generable
struct ProductReview {
    @Guide(description: "Product name", .pattern(/[A-Z][a-zA-Z\s]+/))
    let productName: String
    
    @Guide(description: "Rating from 1 to 5", .range(1...5))
    let rating: Int
    
    @Guide(description: "Review text", .count(50...200))
    let reviewText: String
    
    @Guide(description: "Would recommend", .anyOf(["Yes", "No", "Maybe"]))
    let recommendation: String
}
```

### Streaming Responses

```swift
let session = LanguageModelSession()
let stream = session.streamResponse(
    to: "Write a short story about space exploration",
    generating: [String].self
)

for try await partialContent in stream {
    // Update UI with streaming content
    updateUI(with: partialContent)
}

// Get final result
let finalResponse = try await stream.collect()
```

### Custom Tools

```swift
struct WeatherTool: Tool {
    let name = "get_weather"
    let description = "Gets current weather for a location"
    
    @Generable
    struct Arguments {
        @Guide(description: "City name")
        let city: String
        
        @Guide(description: "Country code (optional)")
        let country: String?
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        // Fetch weather data
        let weatherData = try await fetchWeather(
            city: arguments.city,
            country: arguments.country
        )
        return ToolOutput(weatherData)
    }
}

// Use tool in session
let session = LanguageModelSession(tools: [WeatherTool()])
let response = try await session.respond(to: "What's the weather like in San Francisco?")
```

### Dynamic Schema Generation

```swift
// Create schemas at runtime
let personSchema = DynamicGenerationSchema(
    name: "Person",
    description: "A person with basic information",
    properties: [
        .init(name: "name", description: "Full name", schema: .init(type: String.self)),
        .init(name: "age", description: "Age in years", schema: .init(type: Int.self)),
        .init(name: "email", description: "Email address", schema: .init(type: String.self))
    ]
)

let generationSchema = try GenerationSchema(
    root: personSchema,
    dependencies: []
)

let response = try await session.respond(
    to: "Create a person profile for a software engineer",
    schema: generationSchema
)
```

### Model Availability and Configuration

```swift
// Check model availability
let model = SystemLanguageModel.default
switch model.availability {
case .available:
    print("Model is ready to use")
case .unavailable(let reason):
    switch reason {
    case .deviceNotEligible:
        print("Device doesn't support Apple Intelligence")
    case .appleIntelligenceNotEnabled:
        print("Apple Intelligence is not enabled")
    case .modelNotReady:
        print("Model is downloading...")
    }
}

// Use specialized models
let contentTaggingModel = SystemLanguageModel(useCase: .contentTagging)
let session = LanguageModelSession(model: contentTaggingModel)
```

### Generation Options and Sampling

```swift
let options = GenerationOptions(
    sampling: .random(top: 10, seed: 42),
    temperature: 0.7,
    maximumResponseTokens: 500
)

let response = try await session.respond(
    to: "Write a creative story",
    options: options
)
```

### Error Handling

```swift
do {
    let response = try await session.respond(to: prompt)
    print(response.content)
} catch let error as LanguageModelSession.GenerationError {
    switch error {
    case .exceededContextWindowSize(let context):
        print("Context too large: \(context.debugDescription)")
        // Start new session or shorten prompt
    case .assetsUnavailable(let context):
        print("Model assets unavailable: \(context.debugDescription)")
        // Retry later or check availability
    case .guardrailViolation(let context):
        print("Content policy violation: \(context.debugDescription)")
        // Modify prompt to comply with policies
    case .decodingFailure(let context):
        print("Failed to decode response: \(context.debugDescription)")
        // Handle malformed response
    default:
        print("Generation error: \(error.localizedDescription)")
    }
} catch let toolError as LanguageModelSession.ToolCallError {
    print("Tool call failed: \(toolError.localizedDescription)")
    print("Tool: \(toolError.tool.name)")
}
```

### Transcript Management

```swift
// Save conversation history
let transcript = session.transcript
let data = try JSONEncoder().encode(transcript)
UserDefaults.standard.set(data, forKey: "conversation_history")

// Restore from saved transcript
if let data = UserDefaults.standard.data(forKey: "conversation_history") {
    let savedTranscript = try JSONDecoder().decode(Transcript.self, from: data)
    let restoredSession = LanguageModelSession(transcript: savedTranscript)
}
```

### Content Generation with Partially Generated Types

```swift
@Generable
struct BlogPost {
    @Guide(description: "Blog post title")
    let title: String
    
    @Guide(description: "Blog post content", .count(500...1000))
    let content: String
    
    @Guide(description: "List of tags", .count(3...5))
    let tags: [String]
}

// Stream partial results
let stream = session.streamResponse(
    to: "Write a blog post about sustainable living",
    generating: BlogPost.self
)

for try await partialPost in stream {
    // Access partially generated content
    print("Title (partial): \(partialPost.title)")
    // UI can update in real-time as content generates
    updateBlogPostUI(partialPost)
}
```

## Project Structure

```
FMF/
├── FMF/
│   ├── FMFApp.swift          # App entry point
│   ├── ContentView.swift     # Main UI with examples
│   └── Assets.xcassets/      # App assets
├── FMF.xcodeproj/           # Xcode project
└── README.md                # This file
```

## Key Framework Components

### Core Classes

- **`LanguageModelSession`**: Main interface for interacting with language models
- **`SystemLanguageModel`**: Represents the system's language model
- **`GeneratedContent`**: Container for model-generated structured data
- **`Transcript`**: Records conversation history

### Protocols

- **`Generable`**: Mark types that can be generated by the model
- **`Tool`**: Define custom tools the model can call
- **`PromptRepresentable`**: Types that can be converted to prompts
- **`InstructionsRepresentable`**: Types that can be used as instructions

### Macros

- **`@Generable`**: Automatically implements `Generable` protocol
- **`@Guide`**: Provides generation constraints and descriptions

## Best Practices

1. **Model Availability**: Always check model availability before use
2. **Error Handling**: Implement comprehensive error handling for various failure modes
3. **Memory Management**: Use sessions efficiently to manage context window size
4. **Privacy**: All processing happens on-device for user privacy
5. **Performance**: Consider using streaming for long responses
6. **Constraints**: Use generation guides to ensure consistent output format

## Privacy and Security

Foundation Models framework operates entirely on-device, ensuring:
- No data sent to external servers
- Complete user privacy
- Offline functionality
- Compliance with Apple's privacy standards

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Resources

- [Apple Foundation Models Documentation](https://developer.apple.com/documentation/foundationmodels)
- [Apple Intelligence Developer Resources](https://developer.apple.com/apple-intelligence/)
- [WWDC 2024 Sessions on Apple Intelligence](https://developer.apple.com/videos/) 