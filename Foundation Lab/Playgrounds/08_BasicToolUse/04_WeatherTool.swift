//
//  04_WeatherTool.swift
//  Exploring Foundation Models
//
//  Created by Rudrank Riyam on 9/24/25.
//

import Foundation
import FoundationModels
import Playgrounds

struct MockWeatherTool: Tool {
    let name = "getCurrentWeather"
    let description = "Gets current weather conditions for a specific city including temperature, humidity, and " +
                      "conditions"

    @Generable
    struct Arguments {
        @Guide(description: "The city name to get weather for")
        var city: String

        @Guide(description: "Country code (optional, e.g., 'US', 'UK')")
        var countryCode: String?
    }

    @Generable
    struct WeatherData {
        let city: String
        let country: String
        let temperature: Double
        let feelsLike: Double
        let humidity: Int
        let conditions: String
        let description: String
        let windSpeed: Double
    }

    func call(arguments: Arguments) async throws -> WeatherData {
        let city = arguments.city.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !city.isEmpty else {
            throw WeatherError.emptyCity
        }

        // In a real implementation, you would:
        // 1. Make API call to OpenMeteo or another weather service
        // 2. Parse the JSON response
        // 3. Return structured weather data

        // Mock weather data for demonstration
        let mockWeatherData = generateMockWeatherData(for: city, countryCode: arguments.countryCode)

        print("THIS IS CALLED")

        return mockWeatherData
    }

    @available(iOS 26.1, macOS 26.1, *)
    private func findRecentLocationData(in transcript: Transcript) -> MockLocationTool.LocationData? {
        // Look through recent transcript entries for location tool calls
        for entry in transcript.reversed() {
            if case .toolOutput(let output) = entry,
               output.toolName == "getUserLocation" {

                // Try to extract location data from the tool output
                // In a real implementation, you'd parse the structured output
                if let locationData = extractLocationData(from: output) {
                    return locationData
                }
            }
        }
        return nil
    }

    @available(iOS 26.1, macOS 26.1, *)
    private func extractLocationData(from output: Transcript.ToolOutput) -> MockLocationTool.LocationData? {
        // In a real implementation, you'd properly parse the tool output
        // For demo purposes, return mock recent location data
        return MockLocationTool.LocationData(
            latitude: 37.7749,
            longitude: -122.4194,
            city: "San Francisco",
            country: "US",
            timestamp: ISO8601DateFormatter().string(from: Date())
        )
    }

    @available(iOS 26.1, macOS 26.1, *)
    private func getWeatherByCoordinates(latitude: Double, longitude: Double, city: String?) async -> WeatherData {
        // In real implementation, use coordinates for precise weather API call
        let displayCity = city ?? "Current Location"

        let baseTemperature = Double.random(in: 18...25) // Slightly different range for coord-based queries
        let humidity = Int.random(in: 45...75)
        let windSpeed = Double.random(in: 8...20)

        let conditions = ["Clear", "Partly Cloudy", "Cloudy", "Sunny"].randomElement()!
        let descriptions = [
            "Clear": "Clear sky with excellent visibility",
            "Partly Cloudy": "Partly cloudy with good weather",
            "Cloudy": "Overcast conditions",
            "Sunny": "Bright and sunny"
        ]

        return WeatherData(
            city: displayCity,
            country: "Coordinates-based",
            temperature: round(baseTemperature * 10) / 10,
            feelsLike: round((baseTemperature + Double.random(in: -2...2)) * 10) / 10,
            humidity: humidity,
            conditions: conditions,
            description: descriptions[conditions] ?? "Weather conditions available",
            windSpeed: round(windSpeed * 10) / 10
        )
    }

    private func generateMockWeatherData(for city: String, countryCode: String?) -> WeatherData {
        // Generate realistic but mock weather data
        let baseTemperature = Double.random(in: 15...30)
        let humidity = Int.random(in: 40...80)
        let windSpeed = Double.random(in: 5...25)

        let conditions = ["Clear", "Partly Cloudy", "Cloudy", "Light Rain", "Sunny"].randomElement()!
        let descriptions = [
            "Clear": "Clear sky with plenty of sunshine",
            "Partly Cloudy": "Partly cloudy with some sunshine",
            "Cloudy": "Overcast with cloudy skies",
            "Light Rain": "Light rain showers expected",
            "Sunny": "Bright and sunny weather"
        ]

        return WeatherData(
            city: city.capitalized,
            country: countryCode?.uppercased() ?? "Unknown",
            temperature: round(baseTemperature * 10) / 10,
            feelsLike: round((baseTemperature + Double.random(in: -3...3)) * 10) / 10,
            humidity: humidity,
            conditions: conditions,
            description: descriptions[conditions] ?? "Weather conditions available",
            windSpeed: round(windSpeed * 10) / 10
        )
    }

    enum WeatherError: Error, LocalizedError {
        case emptyCity
        case networkError
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .emptyCity:
                return "City name cannot be empty"
            case .networkError:
                return "Network connection failed"
            case .invalidResponse:
                return "Invalid weather service response"
            }
        }
    }
}

#Playground {
    let weatherTool = MockWeatherTool()

    let arguments = MockWeatherTool.Arguments(
        city: "San Francisco",
        countryCode: "US"
    )

    let result = try await weatherTool.call(arguments: arguments)
    debugPrint("Weather result: \(result)")
}
