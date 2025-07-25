# Foundation Models Framework Example

![AI interface screenshot with "Foundation Models" title, showcasing on-device AI examples including Basic Chat, Structured Data, Generation Guides, and more; user requests a haiku about destiny, receiving response: "Paths weave through the mist, Stars whisper tales of tomorrow— Destiny unfolds.](main-examples.png)

![A computer window displaying a tool use interface with weather info for San Francisco: 16°C, clear skies, 70% humidity, 18.1 km/h wind speed, 1010.2 hPa pressure. Various tool options include web search, contacts, calendar, reminders, location, health, and music.](tool-use.png)

> Note:- For folks starring it, please do not judge the codebase. I have to do some refactoring that I vibe-coded to ship this, fast. Okay?

A practical iOS app demonstrating Apple's Foundation Models framework with various examples of on-device AI capabilities.

## Exploring AI for iOS Development

Love this project? Check out my books to explore more of AI and iOS development:
- [Exploring AI for iOS Development](https://academy.rudrank.com/product/ai)
- [Exploring AI-Assisted Coding for iOS Development](https://academy.rudrank.com/product/ai-assisted-coding)

## Requirements

- iOS 26.0+ or macOS 26.0+ (Xcode 26.0+) 
- **Beta 4 version of the framework is required**
- Apple Intelligence enabled
- Compatible Apple device with Apple Silicon

## Try it on TestFlight

You can now try Foundation Lab on TestFlight! Join the beta: [https://testflight.apple.com/join/JWR9FpP3](https://testflight.apple.com/join/JWR9FpP3)

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
- **Web Search Tool**: Real-time web search using Exa AI API

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
// Weather Tool
let weatherSession = LanguageModelSession(tools: [WeatherTool()])
let weatherResponse = try await weatherSession.respond(
    to: "Is it hotter in New Delhi or Cupertino?"
)
print(weatherResponse.content)

// Web Search Tool
let webSession = LanguageModelSession(tools: [WebTool()])
let webResponse = try await webSession.respond(
    to: "Search for the latest WWDC 2025 announcements"
)
print(webResponse.content)

// Multiple Tools Example
let multiSession = LanguageModelSession(tools: [
    WeatherTool(),
    WebTool()
])
let multiResponse = try await multiSession.respond(
    to: "Check the weather in Tokyo and search for tourist attractions there"
)
print(multiResponse.content)

// Web Metadata Tool Example
let metadataSession = LanguageModelSession(tools: [WebMetadataTool()])
let metadataResponse = try await metadataSession.respond(
    to: "Generate a Twitter post for https://www.apple.com/newsroom/"
)
print(metadataResponse.content)
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
Provides real-time weather information using OpenMeteo API:
- Fetches current weather for any city worldwide
- Temperature, humidity, wind speed, and weather conditions
- Automatic geocoding for city names
- No API key required

### Web Search Tool
Real-time web search by Exa AI:
- Returns text content from web pages
- Configurable number of results (default: 5)
- Supports complex search queries and current events

**Setup Requirements:**
1. Get an API key from [Exa AI](https://exa.ai)
2. Add your API key in the app's Settings screen
3. The tool will automatically use the stored API key for searches

### Timer Tool
Time-based operations and calculations:
- Get current time in any timezone
- Calculate time differences between dates
- Format durations in human-readable format
- No external dependencies or API keys required

### Math Tool
Mathematical calculations and conversions:
- Basic arithmetic operations (add, subtract, multiply, divide, power, sqrt)
- Statistical calculations (mean, median, standard deviation)
- Unit conversions (temperature, length, weight)
- Works entirely offline

### Text Tool
Text manipulation and analysis:
- Analyze text (word count, character count, statistics)
- Transform text (uppercase, lowercase, camelCase, snake_case)
- Format text (trim, wrap, truncate, remove newlines)
- No external dependencies

### Web Metadata Tool
Webpage metadata extraction and social media summary generation:
- Fetches title, description, and metadata from any URL
- Generates AI-powered summaries optimized for social media
- Supports platform-specific formatting (Twitter, LinkedIn, Facebook)
- Automatic hashtag generation
- No API key required




## Getting Started

1. Clone the repository
2. Open `FMF.xcodeproj` in Xcode
3. Ensure you have a device with Apple Intelligence enabled
4. Build and run the project
5. (Optional) For web search functionality:
   - Get an API key from [Exa AI](https://exa.ai)
   - Tap the gear icon in the app to access Settings
   - Enter your Exa API key in the settings screen
6. Explore the different AI capabilities through the example buttons

**Note:** All features except web search work without any additional setup. The web search tool requires an Exa API key for functionality.



## Contributing

Contributions are welcome! Please feel free to submit a pull request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
