//
//  04_WeatherTool.swift
//  Exploring Foundation Models
//
//  Created by Rudrank Riyam on 9/24/25.
//

import Foundation
import FoundationModels
import Playgrounds

struct WeatherTool: Tool {
    let name = "getCurrentWeather"
    let description = "Gets current weather conditions for a specific city including temperature, humidity, and conditions"

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

        return mockWeatherData
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
    let weatherTool = WeatherTool()

    let arguments = WeatherTool.Arguments(
        city: "San Francisco",
        countryCode: "US"
    )

    let result = try await weatherTool.call(arguments: arguments)
    debugPrint("Weather result: \(result)")
}