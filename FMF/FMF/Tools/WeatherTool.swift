//
//  WeatherTool.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/9/25.
//

import Foundation
import FoundationModels

/// A tool that provides weather information for cities
struct WeatherTool: Tool {
  let name = "getWeather"
  let description = "Retrieve the latest weather information for a city"

  @Generable
  struct Arguments {
    @Guide(description: "The city to get weather information for")
    var city: String
  }

  struct WeatherData: Encodable {
    let city: String
    let temperature: Int
    let condition: String
    let humidity: Int
    let windSpeed: Int
    let unit: String
  }

  private let weatherDatabase: [String: WeatherData] = [
    "Boston": WeatherData(
      city: "Boston", temperature: 72, condition: "Partly Cloudy", humidity: 65, windSpeed: 8,
      unit: "Fahrenheit"),
    "Wichita": WeatherData(
      city: "Wichita", temperature: 89, condition: "Sunny", humidity: 45, windSpeed: 12,
      unit: "Fahrenheit"),
    "Pittsburgh": WeatherData(
      city: "Pittsburgh", temperature: 68, condition: "Overcast", humidity: 70, windSpeed: 6,
      unit: "Fahrenheit"),
    "New York": WeatherData(
      city: "New York", temperature: 75, condition: "Sunny", humidity: 60, windSpeed: 10,
      unit: "Fahrenheit"),
    "Los Angeles": WeatherData(
      city: "Los Angeles", temperature: 82, condition: "Clear", humidity: 40, windSpeed: 5,
      unit: "Fahrenheit"),
    "Chicago": WeatherData(
      city: "Chicago", temperature: 70, condition: "Cloudy", humidity: 68, windSpeed: 15,
      unit: "Fahrenheit"),
    "Miami": WeatherData(
      city: "Miami", temperature: 85, condition: "Humid", humidity: 80, windSpeed: 7,
      unit: "Fahrenheit"),
    "Seattle": WeatherData(
      city: "Seattle", temperature: 65, condition: "Rainy", humidity: 85, windSpeed: 9,
      unit: "Fahrenheit"),
  ]

  func call(arguments: Arguments) async throws -> ToolOutput {
    // Simulate API delay
    try await Task.sleep(for: .milliseconds(500))

    let cityName = arguments.city.trimmingCharacters(in: .whitespacesAndNewlines)

    // Try to find exact match first
    if let weatherData = weatherDatabase[cityName] {
      return ToolOutput(
        GeneratedContent(properties: [
          "city": weatherData.city,
          "temperature": weatherData.temperature,
          "condition": weatherData.condition,
          "humidity": weatherData.humidity,
          "windSpeed": weatherData.windSpeed,
          "unit": weatherData.unit,
        ]))
    }

    // Try case-insensitive search
    if let matchingEntry = weatherDatabase.first(where: {
      $0.key.lowercased() == cityName.lowercased()
    }) {
      let weatherData = matchingEntry.value
      return ToolOutput(
        GeneratedContent(properties: [
          "city": weatherData.city,
          "temperature": weatherData.temperature,
          "condition": weatherData.condition,
          "humidity": weatherData.humidity,
          "windSpeed": weatherData.windSpeed,
          "unit": weatherData.unit,
        ]))
    }

    // Generate random data for unknown cities
    let randomWeather = generateRandomWeather(for: cityName)
    return ToolOutput(
      GeneratedContent(properties: [
        "city": randomWeather.city,
        "temperature": randomWeather.temperature,
        "condition": randomWeather.condition,
        "humidity": randomWeather.humidity,
        "windSpeed": randomWeather.windSpeed,
        "unit": randomWeather.unit,
        "note": "Simulated data for unknown city",
      ]))
  }

  private func generateRandomWeather(for city: String) -> WeatherData {
    let conditions = ["Sunny", "Cloudy", "Partly Cloudy", "Rainy", "Overcast", "Clear"]
    let randomCondition = conditions.randomElement() ?? "Unknown"

    return WeatherData(
      city: city,
      temperature: Int.random(in: 40...100),
      condition: randomCondition,
      humidity: Int.random(in: 30...90),
      windSpeed: Int.random(in: 0...25),
      unit: "Fahrenheit"
    )
  }
}
