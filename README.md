# Foundation Models Framework Example

<div align="center">
  <table>
    <tr>
      <td align="center" style="padding: 15px;">
        <img src="images/FMF_Examples.png" alt="FMF examples - One-shot prompt interface showing a haiku generation example with prompt input, reset/run buttons, suggestions, and resulting haiku about destiny" width="500" style="border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);"/>
        <br/>
        <strong>FMF Examples</strong>
      </td>
      <td align="center" style="padding: 15px;">
        <img src="images/FMF_Tools.png" alt="FMF tools - Tools page showing various utility options including Weather, Web Search, Contacts, Calendar, Reminders, Location, Health, Music, and Web Metadata tools" width="500" style="border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);"/>
        <br/>
        <strong>FMF Tools</strong>
      </td>
    </tr>
    <tr>
      <td align="center" style="padding: 15px;">
        <img src="images/FMF_Chat.png" alt="FMF chat - Chat interface displaying a conversation about the meaning of life, with user messages on the right and AI responses on the left, including a detailed philosophical answer" width="500" style="border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);"/>
        <br/>
        <strong>FMF Chat</strong>
      </td>
      <td align="center" style="padding: 15px;">
        <img src="images/FMF_Languages.png" alt="FMF languages - Languages page showing various language options and language selection interface for the Foundation Models framework" width="500" style="border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);"/>
        <br/>
        <strong>FMF Languages</strong>
      </td>
    </tr>
  </table>
</div>

## Exploring Foundation Models

This project includes playground examples organized by chapters to help you learn everything about Apple's Foundation Models framework. 

It is part of the [Exploring Foundation Models](https://academy.rudrank.com/product/foundation-models) book.

## Requirements

- iOS 26.0+ or macOS 26.0+ (Xcode 26.0+) 
- **Xcode 26 official is required**
- Apple Intelligence enabled
- Compatible Apple device with Apple Silicon

## Try it on TestFlight

You can now try Foundation Lab on TestFlight! Join the beta: [https://testflight.apple.com/join/JWR9FpP3](https://testflight.apple.com/join/JWR9FpP3)

## Getting Started

- Clone the repository
- Open `FoundationLab.xcodeproj` in Xcode
- Ensure you have a device with Apple Intelligence enabled
- Build and run the project
- (Optional) For web search functionality:
  - Get an API key from [Exa AI](https://exa.ai)
  - Tap the gear icon in the app to access Settings
  - Enter your Exa API key in the settings screen
- Explore the different capabilities through the examples!

## Features

- **Basic Chat**: Simple conversational interactions
- **Structured Data Generation**: Type-safe data generation with `@Generable`
- **Generation Guides**: Constrained outputs with `@Guide` annotations
- **Streaming Responses**: Response streaming
- **Tool Calling**: Built-in tools for extended functionality
- **Model Availability**: System capability checking

### Example Tools
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

## Contributing

Contributions are welcome! Please feel free to submit a pull request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
