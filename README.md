# FoundationModelsKit


A collection of tools and utilities for Apple's Foundation Models Framework that help working with the language model, better.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
  - [Privacy Permissions](#privacy-permissions)
  - [API Keys](#api-keys)
- [Tool Reference](#tool-reference)
  - [CalendarTool](#calendartool)
  - [ContactsTool](#contactstool)
  - [HealthTool](#healthtool)
  - [LocationTool](#locationtool)
  - [MusicTool](#musictool)
  - [RemindersTool](#reminderstool)
  - [WeatherTool](#weathertool)
  - [WebMetadataTool](#webmetadatatool)
  - [WebTool](#webtool)
- [Utilities](#utilities)
  - [Token Counting](#token-counting)
  - [Transcript History Transforms](#transcript-history-transforms)
- [Usage Examples](#usage-examples)
  - [Direct Tool Usage](#direct-tool-usage)
  - [Model Integration](#model-integration)
  - [Error Handling](#error-handling)
- [Advanced Topics](#advanced-topics)
  - [Permission Management](#permission-management)
  - [Date Formats](#date-formats)
  - [Return Values](#return-values)
- [Contributing](#contributing)
- [License](#license)

## Overview

**FoundationModelsTools** provides a set of pre-built tools and utilities that extend the capabilities of models using Apple's Foundation Models Framework. These tools allow you to:

- Access and manage calendar events
- Read and create contacts
- Get health data from HealthKit
- Access location services
- Control music playback
- Manage reminders
- Fetch weather information
- Extract metadata from web pages
- Search the web using Exa
- Manage context windows with token counting utilities

## Features

- **Native Apple Framework Integration**: Works seamlessly with EventKit, Contacts, HealthKit, CoreLocation, MapKit, and MusicKit
- **Modern Swift Concurrency**: Built with async/await patterns throughout
- **Type-Safe**: Leverages Swift's type system with the `@Generable` protocol
- **Permission Handling**: Automatic authorization checks for privacy-sensitive operations
- **Cross-Platform**: Supports both iOS and macOS
- **Comprehensive Error Handling**: Detailed error messages for troubleshooting

## Requirements

- macOS 26.0+
- iOS 26.0+
- Swift 6.2+
- Xcode 26.0+

## Installation

Add **FoundationModelsTools** as a dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/rudrankriyam/FoundationModelsTools", from: "0.1.0")
]
```

Then add it to your target dependencies:

```swift
.target(
    name: "YourTarget",
    dependencies: ["FoundationModelsTools"]
)
```

## Quick Start

Here's a simple example to get you started:

```swift
import FoundationModels
import FoundationModelsTools

// Create a weather tool
let weatherTool = WeatherTool()

// Call it directly
let arguments = WeatherTool.Arguments(city: "San Francisco")
let result = try await weatherTool.call(arguments: arguments)

// Access the results
let temperature = result.value(Double.self, forProperty: "temperature")
let condition = result.value(String.self, forProperty: "condition")
print("It's \(temperature)°C and \(condition)")
```

## Configuration

### Privacy Permissions

Add the required usage descriptions to your `Info.plist` for the tools you plan to use:

```xml
<!-- Calendar Access -->
<key>NSCalendarsUsageDescription</key>
<string>This app needs access to your calendar to create and manage events</string>

<!-- Contacts Access -->
<key>NSContactsUsageDescription</key>
<string>This app needs access to your contacts to search and create contact entries</string>

<!-- Health Data Access -->
<key>NSHealthShareUsageDescription</key>
<string>This app needs to read your health data</string>

<!-- Location Access -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs your location to provide location-based services</string>

<!-- Apple Music Access -->
<key>NSAppleMusicUsageDescription</key>
<string>This app needs access to Apple Music to control playback</string>

<!-- Reminders Access -->
<key>NSRemindersUsageDescription</key>
<string>This app needs access to reminders to create and manage tasks</string>
```

### API Keys

**WebTool** requires an Exa API key.

> **⚠️ SECURITY WARNING**
>
> **Do note store API keys directly in your app code or use `@AppStorage` for your production apps.** API keys stored client-side can be extracted from your app bundle and misused.
>
> **Recommended approach:** Make API requests from a secure server where the API key is stored as an environment variable. Your app should call your server endpoint, which then makes the request to Exa's API.

**For development/testing only**, you can configure the key using `@AppStorage`:

```swift
import SwiftUI

@main
struct MyApp: App {
    @AppStorage("exaAPIKey") private var exaAPIKey = ""

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // DEVELOPMENT ONLY - Never ship API keys in production
                    // Get your key from: https://exa.ai
                    exaAPIKey = "your-api-key-here"
                }
        }
    }
}
```

**Production setup:**
1. Create a server endpoint (e.g., `/api/search`)
2. Store your Exa API key in environment variables on the server
3. Your app calls your server endpoint with the search query
4. Your server makes the request to Exa's API and returns the results

## Tool Reference

### CalendarTool

Access and manage calendar events using EventKit.

**Name**: `manageCalendar`

**Actions**: `create`, `query`, `read`, `update`

**Requirements**:
- Calendar entitlement
- User permission via `NSCalendarsUsageDescription`

**Arguments**:
- `action`: The operation to perform
- `title`: Event title (required for create)
- `startDate`: Start date in `YYYY-MM-DD HH:mm:ss` format
- `endDate`: End date in `YYYY-MM-DD HH:mm:ss` format
- `location`: Event location
- `notes`: Additional notes
- `calendarName`: Specific calendar to use (optional)
- `daysAhead`: Number of days to query (default: 7)
- `eventId`: Event identifier for read/update operations

**Example**:

```swift
let calendarTool = CalendarTool()

// Create an event
let createArgs = CalendarTool.Arguments(
    action: "create",
    title: "Team Meeting",
    startDate: "2025-11-15 14:00:00",
    endDate: "2025-11-15 15:00:00",
    location: "Conference Room A",
    notes: "Discuss Q4 planning"
)
let result = try await calendarTool.call(arguments: createArgs)

// Query upcoming events
let queryArgs = CalendarTool.Arguments(
    action: "query",
    daysAhead: 7
)
let events = try await calendarTool.call(arguments: queryArgs)
print(events.value(String.self, forProperty: "events"))
```

**Returns**:
- `status`: "success" or "error"
- `eventId`: Unique event identifier
- `title`: Event title
- `startDate`: Formatted start date
- `endDate`: Formatted end date
- `location`: Event location
- `calendar`: Calendar name

### ContactsTool

Search, read, and create contacts using the Contacts framework.

**Name**: `manageContacts`

**Actions**: `search`, `read`, `create`

**Requirements**:
- Contacts entitlement
- User permission via `NSContactsUsageDescription`

**Arguments**:
- `action`: The operation to perform
- `name`: Name to search for (for search action)
- `contactId`: Contact identifier (for read action)
- `firstName`: First name (for create action)
- `lastName`: Last name (for create action)
- `phoneNumber`: Phone number (for create action)
- `email`: Email address (for create action)
- `organization`: Company/organization (for create action)

**Example**:

```swift
let contactsTool = ContactsTool()

// Search for contacts
let searchArgs = ContactsTool.Arguments(
    action: "search",
    name: "John"
)
let results = try await contactsTool.call(arguments: searchArgs)

// Create a new contact
let createArgs = ContactsTool.Arguments(
    action: "create",
    firstName: "Jane",
    lastName: "Doe",
    email: "jane.doe@example.com",
    phoneNumber: "+1234567890",
    organization: "Acme Corp"
)
let contact = try await contactsTool.call(arguments: createArgs)
```

**Returns**:
- `status`: "success" or "error"
- `contactId`: Unique contact identifier
- `givenName`: First name
- `familyName`: Last name
- `fullName`: Combined full name
- `emails`: Array of email addresses
- `phoneNumbers`: Array of phone numbers
- `organization`: Company name

### HealthTool

Read health data from HealthKit including steps, heart rate, workouts, and more.

**Name**: `accessHealth`

**Data Types**: `steps`, `heartRate`, `workouts`, `sleep`, `activeEnergy`, `distance`

**Requirements**:
- HealthKit capability
- User permission via `NSHealthShareUsageDescription`

**Arguments**:
- `dataType`: Type of health data to query
- `startDate`: Start date in `YYYY-MM-DD` format (optional, defaults to 7 days ago)
- `endDate`: End date in `YYYY-MM-DD` format (optional, defaults to today)

**Example**:

```swift
let healthTool = HealthTool()

// Query steps for the last 7 days
let stepsArgs = HealthTool.Arguments(
    dataType: "steps",
    startDate: "2025-11-07",
    endDate: "2025-11-14"
)
let steps = try await healthTool.call(arguments: stepsArgs)
print("Total steps: \(steps.value(Int.self, forProperty: "totalSteps"))")

// Query heart rate
let heartArgs = HealthTool.Arguments(dataType: "heartRate")
let heartRate = try await healthTool.call(arguments: heartArgs)

// Query workouts
let workoutsArgs = HealthTool.Arguments(
    dataType: "workouts",
    startDate: "2025-11-01",
    endDate: "2025-11-14"
)
let workouts = try await healthTool.call(arguments: workoutsArgs)
```

**Returns** (varies by data type):
- `status`: "success" or "error"
- `dataType`: Type of data returned
- `totalSteps`: Total step count (for steps)
- `averageBPM`: Average heart rate (for heartRate)
- `workoutCount`: Number of workouts (for workouts)
- `averageSleepHours`: Average sleep duration (for sleep)
- `totalCalories`: Total active energy (for activeEnergy)

### LocationTool

Get current location, geocode addresses, search places, and calculate distances.

**Name**: `accessLocation`

**Actions**: `current`, `geocode`, `reverse`, `search`, `distance`

**Requirements**:
- Location Services capability
- User permission via `NSLocationWhenInUseUsageDescription`

**Arguments**:
- `action`: The operation to perform
- `address`: Address to geocode (for geocode action)
- `latitude`: Latitude coordinate
- `longitude`: Longitude coordinate
- `latitude2`: Second latitude (for distance action)
- `longitude2`: Second longitude (for distance action)
- `searchQuery`: Search query for places (for search action)
- `radius`: Search radius in meters (default: 1000)

**Example**:

```swift
let locationTool = LocationTool()

// Get current location
let currentArgs = LocationTool.Arguments(action: "current")
let location = try await locationTool.call(arguments: currentArgs)

// Geocode an address
let geocodeArgs = LocationTool.Arguments(
    action: "geocode",
    address: "1 Apple Park Way, Cupertino, CA"
)
let coordinates = try await locationTool.call(arguments: geocodeArgs)

// Reverse geocode coordinates
let reverseArgs = LocationTool.Arguments(
    action: "reverse",
    latitude: 37.3349,
    longitude: -122.0090
)
let address = try await locationTool.call(arguments: reverseArgs)

// Search for nearby places
let searchArgs = LocationTool.Arguments(
    action: "search",
    searchQuery: "coffee shop",
    radius: 2000
)
let places = try await locationTool.call(arguments: searchArgs)

// Calculate distance between two points
let distanceArgs = LocationTool.Arguments(
    action: "distance",
    latitude: 37.3349,
    longitude: -122.0090,
    latitude2: 37.7749,
    longitude2: -122.4194
)
let distance = try await locationTool.call(arguments: distanceArgs)
```

**Returns**:
- `status`: "success" or "error"
- `latitude`: Latitude coordinate
- `longitude`: Longitude coordinate
- `address`: Formatted address string
- `distanceMeters`: Distance in meters (for distance action)
- `bearing`: Compass bearing (for distance action)
- `direction`: Cardinal direction (N, NE, E, etc.)

### MusicTool

Control music playback and search the Apple Music catalog.

**Name**: `controlMusic`

**Actions**: `search`, `play`, `pause`, `stop`, `skip`, `previous`, `nowPlaying`

**Requirements**:
- MusicKit capability
- User permission via `NSAppleMusicUsageDescription`

**Arguments**:
- `action`: The operation to perform
- `query`: Search query (for search action)
- `trackId`: Track identifier (for play action)

**Example**:

```swift
let musicTool = MusicTool()

// Search for music
let searchArgs = MusicTool.Arguments(
    action: "search",
    query: "Bohemian Rhapsody"
)
let results = try await musicTool.call(arguments: searchArgs)

// Get now playing
let nowPlayingArgs = MusicTool.Arguments(action: "nowPlaying")
let currentTrack = try await musicTool.call(arguments: nowPlayingArgs)

// Control playback
let pauseArgs = MusicTool.Arguments(action: "pause")
try await musicTool.call(arguments: pauseArgs)
```

**Returns**:
- `status`: "success" or "error"
- `results`: Search results with track information
- `title`: Track title
- `artist`: Artist name
- `album`: Album name

### RemindersTool

Create, read, update, and complete reminders using EventKit.

**Name**: `manageReminders`

**Actions**: `create`, `query`, `complete`, `update`, `delete`

**Requirements**:
- Reminders entitlement
- User permission via `NSRemindersUsageDescription`

**Arguments**:
- `action`: The operation to perform
- `title`: Reminder title (required for create)
- `notes`: Additional notes
- `dueDate`: Due date in `YYYY-MM-DD HH:mm:ss` format
- `priority`: Priority level (`none`, `low`, `medium`, `high`)
- `listName`: Reminder list name (optional)
- `reminderId`: Reminder identifier (for update/complete/delete)
- `filter`: Query filter (`all`, `incomplete`, `completed`, `today`, `overdue`)

**Example**:

```swift
let remindersTool = RemindersTool()

// Create a reminder
let createArgs = RemindersTool.Arguments(
    action: "create",
    title: "Buy groceries",
    dueDate: "2025-11-15 18:00:00",
    priority: "high",
    notes: "Milk, bread, eggs"
)
let reminder = try await remindersTool.call(arguments: createArgs)

// Query incomplete reminders
let queryArgs = RemindersTool.Arguments(
    action: "query",
    filter: "incomplete"
)
let reminders = try await remindersTool.call(arguments: queryArgs)

// Complete a reminder
let completeArgs = RemindersTool.Arguments(
    action: "complete",
    reminderId: "reminder-id-here"
)
try await remindersTool.call(arguments: completeArgs)

// Update a reminder
let updateArgs = RemindersTool.Arguments(
    action: "update",
    reminderId: "reminder-id-here",
    title: "Buy groceries and household items",
    priority: "medium"
)
try await remindersTool.call(arguments: updateArgs)
```

**Returns**:
- `status`: "success" or "error"
- `reminderId`: Unique reminder identifier
- `title`: Reminder title
- `list`: List name
- `dueDate`: Formatted due date
- `priority`: Priority level string

### WeatherTool

Fetch real-time weather information using the OpenMeteo API.

**Name**: `getWeather`

**API**: OpenMeteo (free, no API key required)

**Arguments**:
- `city`: City name (e.g., "New York", "London", "Tokyo")

**Example**:

```swift
let weatherTool = WeatherTool()

// Get weather for a city
let arguments = WeatherTool.Arguments(city: "San Francisco")
let weather = try await weatherTool.call(arguments: arguments)

// Access weather data
let temperature = weather.value(Double.self, forProperty: "temperature")
let condition = weather.value(String.self, forProperty: "condition")
let humidity = weather.value(Double.self, forProperty: "humidity")
let windSpeed = weather.value(Double.self, forProperty: "windSpeed")

print("\(temperature)°C, \(condition)")
print("Humidity: \(humidity)%, Wind: \(windSpeed) km/h")
```

**Returns**:
- `city`: City name
- `temperature`: Current temperature in Celsius
- `condition`: Weather condition description
- `humidity`: Humidity percentage
- `windSpeed`: Wind speed in km/h
- `feelsLike`: Feels-like temperature in Celsius
- `pressure`: Atmospheric pressure in hPa
- `precipitation`: Precipitation in mm
- `unit`: Temperature unit (always "Celsius")

### WebMetadataTool

Extract metadata from web pages using the LinkPresentation framework.

**Name**: `getWebMetadata`

**Arguments**:
- `url`: Web page URL

**Example**:

```swift
let webMetadataTool = WebMetadataTool()

let arguments = WebMetadataTool.Arguments(
    url: "https://www.example.com"
)
let metadata = try await webMetadataTool.call(arguments: arguments)

let title = metadata.value(String.self, forProperty: "title")
let description = metadata.value(String.self, forProperty: "description")
```

**Returns**:
- `status`: "success" or "error"
- `url`: Original URL
- `title`: Page title
- `description`: Page description
- `imageUrl`: Preview image URL

### WebTool

Search the web using Exa's neural and keyword search capabilities.

**Name**: `searchWeb`

**Requirements**:
- Exa API key (sign up at https://exa.ai)
- API key stored in `@AppStorage("exaAPIKey")`

**Arguments**:
- `query`: Search query
- `numResults`: Number of results to return (default: 10)
- `searchType`: Search mode (`neural` or `keyword`)

**Example**:

```swift
// First, configure the API key
@AppStorage("exaAPIKey") var exaAPIKey = "your-exa-api-key"

let webTool = WebTool()

// Neural search (semantic understanding)
let neuralArgs = WebTool.Arguments(
    query: "latest advances in machine learning",
    numResults: 5,
    searchType: "neural"
)
let neuralResults = try await webTool.call(arguments: neuralArgs)

// Keyword search (traditional)
let keywordArgs = WebTool.Arguments(
    query: "Swift 6 concurrency",
    numResults: 10,
    searchType: "keyword"
)
let keywordResults = try await webTool.call(arguments: keywordArgs)
```

**Returns**:
- `status`: "success" or "error"
- `results`: Array of search results with titles, URLs, and snippets
- `count`: Number of results returned

## Utilities

### Token Counting

FoundationModelsTools provides comprehensive token counting and context window management utilities for `Transcript` objects. These utilities help you prevent context overflow and manage long conversations effectively.

#### Features

**Estimation Methods:**
- `estimatedTokenCount` - Basic token counting using Apple's 4.5 characters per token ratio
- `safeEstimatedTokenCount` - Conservative estimate with 25% buffer + 100 token overhead

**Context Management:**
- `isApproachingLimit(threshold:maxTokens:)` - Check if approaching context limits
- `entriesWithinTokenBudget(_:)` - Sliding window implementation for long conversations
- `rollingWindow(entries:)` - Keep the most recent transcript entries by count
- `droppingCompletedToolCalls()` - Remove older completed tool-call exchanges

#### Basic Token Counting

```swift
import FoundationModels
import FoundationModelsTools

let transcript = Transcript([
    .instructions("You are a helpful assistant"),
    .prompt("What's the weather like?"),
    .response("The weather is sunny and 72°F")
])

// Get token estimate
let tokens = transcript.estimatedTokenCount
print("Estimated tokens: \(tokens)")

// Get safe estimate with buffer
let safeTokens = transcript.safeEstimatedTokenCount
print("Safe estimate: \(safeTokens)")
```

#### Context Window Management

```swift
// Check if approaching limit (default: 70% of 4096 tokens)
if transcript.isApproachingLimit() {
    print("Warning: Approaching context limit")
}

// Custom threshold and max tokens
if transcript.isApproachingLimit(threshold: 0.8, maxTokens: 8192) {
    print("Using 80% threshold with 8K token limit")
}
```

#### Sliding Window for Long Conversations

When conversations exceed token limits, use `entriesWithinTokenBudget(_:)` to maintain recent context:

```swift
let maxTokens = 2000
let trimmedEntries = transcript.entriesWithinTokenBudget(maxTokens)
let newTranscript = Transcript(trimmedEntries)

// The trimmed transcript:
// - Includes the first instructions entry if it fits within the budget
// - Includes as many recent entries as possible within budget
// - Preserves conversation recency
```

### Transcript History Transforms

Use entry-level history transforms when you want lightweight transcript cleanup before building the next session or prompt history.

```swift
let compactEntries = transcript
    .droppingCompletedToolCalls()
    .rollingWindow(entries: 10)
```

`rollingWindow(entries:)` keeps the latest entries exactly by count. `droppingCompletedToolCalls()` removes older tool-call and tool-output entries while preserving the latest active tool exchange and all non-tool entries.

#### Token Estimation Functions

For standalone text or structured content:

```swift
// Estimate tokens from text
let textTokens = estimateTokens(from: "Hello, world!")
print("Text tokens: \(textTokens)")

// Estimate tokens from GeneratedContent
let content = GeneratedContent(...)
let contentTokens = estimateTokens(from: content)
print("Content tokens: \(contentTokens)")
```

#### Best Practices

1. **Use Safe Estimates:** Always use `safeEstimatedTokenCount` for critical decisions to account for estimation variance
2. **Set Conservative Thresholds:** Default 70% threshold provides buffer for response generation
3. **Preserve Instructions:** The sliding window attempts to keep the first system instructions entry for consistency, provided it fits within the token budget
4. **Monitor Long Conversations:** Check token counts periodically in chat applications

#### Example: Chat with Token Management

```swift
import FoundationModels
import FoundationModelsTools

class ChatManager {
    private var transcript = Transcript()
    private let maxTokens = 4096
    private let threshold = 0.7

    init(systemInstructions: String) {
        transcript = Transcript([.instructions(systemInstructions)])
    }

    func addMessage(_ message: String) async throws -> String {
        // Add user message
        transcript.append(.prompt(message))

        // Check if we're approaching the limit
        if transcript.isApproachingLimit(threshold: threshold, maxTokens: maxTokens) {
            // Trim to fit budget (leaving room for response)
            let budget = Int(Double(maxTokens) * 0.6) // Use 60% for history
            let trimmedEntries = transcript.entriesWithinTokenBudget(budget)
            transcript = Transcript(trimmedEntries)
            print("Trimmed transcript to \(transcript.estimatedTokenCount) tokens")
        }

        // Generate response with managed context
        let session = LanguageModelSession(model: .instant)
        let response = try await session.generate(from: transcript)
        transcript.append(.response(response))

        return response.text
    }
}
```

## Usage Examples

### Direct Tool Usage

Call tools directly without model integration:

```swift
import FoundationModelsTools

// Weather example
let weatherTool = WeatherTool()
let args = WeatherTool.Arguments(city: "Tokyo")
let result = try await weatherTool.call(arguments: args)

// Check for errors
if let error = result.value(String?.self, forProperty: "error") {
    print("Error: \(error)")
} else {
    let temp = result.value(Double.self, forProperty: "temperature")
    print("Temperature: \(temp)°C")
}
```

### Model Integration

Use tools with Foundation Models:

```swift
import FoundationModels
import FoundationModelsTools

// Create model with tools
let model = LanguageModel.instant

let agent = Agent(
    model: model,
    tools: [
        CalendarTool(),
        LocationTool(),
        WeatherTool(),
        RemindersTool()
    ]
)

// The model can now use these tools
let response = try await agent.generate(
    from: "What's the weather in New York and add a reminder to check it tomorrow?"
)
print(response.text)
```

### Error Handling

All tools return structured results with error information:

```swift
let calendarTool = CalendarTool()

do {
    let result = try await calendarTool.call(
        arguments: CalendarTool.Arguments(
            action: "create",
            title: "Meeting",
            startDate: "invalid-date"
        )
    )

    // Check status
    let status = result.value(String.self, forProperty: "status")
    if status == "error" {
        let errorMessage = result.value(String.self, forProperty: "error")
        print("Tool error: \(errorMessage)")
    } else {
        print("Success!")
    }
} catch {
    print("Exception: \(error.localizedDescription)")
}
```

## Advanced Topics

### Permission Management

All tools that require system permissions handle authorization automatically:

1. **First Time**: Tools will request permission when first called
2. **Denied**: If denied, tools return an error with guidance
3. **Granted**: Subsequent calls work without additional prompts

Example permission flow:

```swift
let locationTool = LocationTool()

// First call - requests permission
let result = try await locationTool.call(
    arguments: LocationTool.Arguments(action: "current")
)

let status = result.value(String.self, forProperty: "status")
if status == "error" {
    // Check if it's a permission error
    let error = result.value(String.self, forProperty: "error")
    if error.contains("permission") {
        print("Please grant location permission in Settings")
    }
}
```

### Date Formats

Tools use consistent date formats:

**Calendar and Reminders**:
- Format: `YYYY-MM-DD HH:mm:ss`
- Example: `2025-11-15 14:30:00`
- 24-hour time format

**Health Data**:
- Format: `YYYY-MM-DD`
- Example: `2025-11-15`
- Time component not required

Alternative formats supported by RemindersTool:
- `YYYY-MM-DD HH:mm` (without seconds)
- `MM/DD/YYYY HH:mm:ss` (US format)
- ISO 8601 format

### Return Values

All tools return `GeneratedContent` with a consistent structure:

```swift
let result = try await someTool.call(arguments: args)

// Access values with type safety
let stringValue = result.value(String.self, forProperty: "propertyName")
let intValue = result.value(Int.self, forProperty: "count")
let doubleValue = result.value(Double.self, forProperty: "temperature")
let boolValue = result.value(Bool.self, forProperty: "isCompleted")

// Optional values
let optionalString = result.value(String?.self, forProperty: "notes")
```

Common properties across all tools:
- `status`: Always "success" or "error"
- `message`: Human-readable message
- `error`: Error description (only present when status is "error")

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

[MIT License](LICENSE)

[![Star History Chart](https://api.star-history.com/svg?repos=rryam/FoundationModelsKit&type=Date)](https://star-history.com/#rryam/FoundationModelsKit&Date)
