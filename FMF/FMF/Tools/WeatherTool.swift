//
//  WeatherTool.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/9/25.
//
//  This file defines the WeatherTool, a utility for retrieving real-time weather information for cities using the OpenMeteo API.
//  The tool provides temperature, humidity, wind speed, and other weather metrics for a given city.
//

import CoreLocation
import Foundation
import FoundationModels
import MapKit

/// `WeatherTool` is a utility that provides real-time weather information for cities using the OpenMeteo API.
///
/// This tool fetches the latest weather data, including temperature, humidity, wind speed, and more, for a specified city.
/// It uses geocoding to resolve city names to coordinates and then queries the OpenMeteo API for current weather conditions.
struct WeatherTool: Tool {

  /// The name of the tool, used for identification.
  let name = "getWeather"
  /// A brief description of the tool's functionality.
  let description = "Retrieve the latest weather information for a city using OpenMeteo API"

  /// Arguments required to fetch weather information.
  @Generable
  struct Arguments {
    /// The city to get weather information for (e.g., "New York", "London", "Tokyo").
    @Guide(
      description: "The city to get weather information for (e.g., 'New York', 'London', 'Tokyo')")
    var city: String
  }

  /// The weather data returned by the tool.
  struct WeatherData: Encodable {

    /// The name of the city.
    let city: String
    /// The current temperature in Celsius.
    let temperature: Double
    /// A textual description of the weather condition.
    let condition: String
    /// The current humidity percentage.
    let humidity: Double
    /// The current wind speed in km/h.
    let windSpeed: Double
    /// The 'feels like' temperature in Celsius.
    let feelsLike: Double
    /// The current atmospheric pressure in hPa.
    let pressure: Double
    /// The current precipitation in mm.
    let precipitation: Double
    /// The unit of temperature (e.g., "Celsius").
    let unit: String
  }

  private struct OpenMeteoResponse: Codable {
    let current: CurrentWeather

    struct CurrentWeather: Codable {
      let temperature: Double
      let windspeed: Double
      let relativehumidity: Double
      let apparentTemperature: Double
      let precipitation: Double
      let pressure: Double
      let weathercode: Int

      enum CodingKeys: String, CodingKey {
        case temperature = "temperature_2m"
        case windspeed = "windspeed_10m"
        case relativehumidity = "relative_humidity_2m"
        case apparentTemperature = "apparent_temperature"
        case precipitation
        case pressure = "surface_pressure"
        case weathercode
      }
    }
  }

  func call(arguments: Arguments) async throws -> ToolOutput {
    let cityName = arguments.city.trimmingCharacters(in: .whitespacesAndNewlines)

    do {
      let coordinates = try await getCoordinates(for: cityName)
      let weatherData = try await fetchWeatherFromOpenMeteo(
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
        cityName: cityName
      )

      return createSuccessOutput(from: weatherData)
    } catch {
      return createErrorOutput(for: cityName, error: error)
    }
  }

  private func getCoordinates(for city: String) async throws -> CLLocationCoordinate2D {
    return try await withCheckedThrowingContinuation { continuation in
      let geocoder = CLGeocoder()
      geocoder.geocodeAddressString(city) { placemarks, error in
        if let coordinate = placemarks?.first?.location?.coordinate {
          continuation.resume(returning: coordinate)
        } else {
          continuation.resume(throwing: WeatherError.locationNotFound)
        }
      }
    }
  }

  private func fetchWeatherFromOpenMeteo(
    latitude: Double,
    longitude: Double,
    cityName: String
  ) async throws -> WeatherData {
    let baseURL = "https://api.open-meteo.com/v1/forecast"
    var components = URLComponents(string: baseURL)
    components?.queryItems = [
      URLQueryItem(name: "latitude", value: "\(latitude)"),
      URLQueryItem(name: "longitude", value: "\(longitude)"),
      URLQueryItem(
        name: "current",
        value:
          "temperature_2m,relative_humidity_2m,apparent_temperature,surface_pressure,precipitation,windspeed_10m,weathercode"
      ),
    ]

    guard let url = components?.url else {
      throw WeatherError.invalidURL
    }

    let (data, response) = try await URLSession.shared.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse,
      httpResponse.statusCode == 200
    else {
      throw WeatherError.apiError
    }

    let openMeteoResponse = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
    let current = openMeteoResponse.current

    return WeatherData(
      city: cityName,
      temperature: current.temperature,
      condition: weatherCondition(from: current.weathercode),
      humidity: current.relativehumidity,
      windSpeed: current.windspeed,
      feelsLike: current.apparentTemperature,
      pressure: current.pressure,
      precipitation: current.precipitation,
      unit: "Celsius"
    )
  }

  private func weatherCondition(from code: Int) -> String {
    switch code {
    case 0: return "Clear sky"
    case 1, 2, 3: return "Partly cloudy"
    case 45, 48: return "Fog"
    case 51, 53, 55: return "Drizzle"
    case 56, 57: return "Freezing drizzle"
    case 61, 63, 65: return "Rain"
    case 66, 67: return "Freezing rain"
    case 71, 73, 75: return "Snow"
    case 77: return "Snow grains"
    case 80, 81, 82: return "Rain showers"
    case 85, 86: return "Snow showers"
    case 95: return "Thunderstorm"
    case 96, 99: return "Thunderstorm with hail"
    default: return "Unknown"
    }
  }

  private func createSuccessOutput(from weatherData: WeatherData) -> ToolOutput {
    return ToolOutput(
      GeneratedContent(properties: [
        "city": weatherData.city,
        "temperature": weatherData.temperature,
        "condition": weatherData.condition,
        "humidity": weatherData.humidity,
        "windSpeed": weatherData.windSpeed,
        "feelsLike": weatherData.feelsLike,
        "pressure": weatherData.pressure,
        "precipitation": weatherData.precipitation,
        "unit": weatherData.unit,
      ]))
  }

  private func createErrorOutput(for cityName: String, error: Error) -> ToolOutput {
    return ToolOutput(
      GeneratedContent(properties: [
        "city": cityName,
        "error": "Unable to fetch weather data: \(error.localizedDescription)",
        "temperature": 0,
        "condition": "Unknown",
        "humidity": 0,
        "windSpeed": 0,
        "feelsLike": 0,
        "pressure": 0,
        "precipitation": 0,
        "unit": "Celsius",
      ]))
  }
}

enum WeatherError: Error, LocalizedError {
  case locationNotFound
  case invalidURL
  case apiError

  var errorDescription: String? {
    switch self {
    case .locationNotFound:
      return "Could not find location for the specified city"
    case .invalidURL:
      return "Invalid API URL"
    case .apiError:
      return "Weather API request failed"
    }
  }
}
