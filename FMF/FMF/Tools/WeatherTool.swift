//
//  WeatherTool.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/9/25.
//

import CoreLocation
import Foundation
import FoundationModels
import MapKit

/// A tool that provides real weather information for cities using OpenMeteo API
struct WeatherTool: Tool {
  let name = "getWeather"
  let description = "Retrieve the latest weather information for a city using OpenMeteo API"

  @Generable
  struct Arguments {
    @Guide(
      description: "The city to get weather information for (e.g., 'New York', 'London', 'Tokyo')")
    var city: String
  }

  struct WeatherData: Encodable {
    let city: String
    let temperature: Double
    let condition: String
    let humidity: Double
    let windSpeed: Double
    let feelsLike: Double
    let pressure: Double
    let precipitation: Double
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
    print("WeatherTool.call(arguments:) called with city: \(cityName)")

    do {
      // Get coordinates for the city
      print("Attempting to get coordinates for city: \(cityName)")
      let coordinates = try await getCoordinates(for: cityName)
      print("Obtained coordinates: \(coordinates)")

      // Fetch weather data from OpenMeteo
      print("Fetching weather for latitude: \(coordinates.latitude), longitude: \(coordinates.longitude)")
      let weatherData = try await fetchWeatherFromOpenMeteo(
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
        cityName: cityName
      )
      print("Weather data fetched: \(weatherData)")

      let output = ToolOutput(
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
      print("Returning successful ToolOutput for city: \(cityName)")
      return output
    } catch {
      print("Error in WeatherTool.call: \(error)")
      // Return error information in a structured way
      let output = ToolOutput(
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
      print("Returning error ToolOutput for city: \(cityName) with error: \(error.localizedDescription)")
      return output
    }
  }

  private func getCoordinates(for city: String) async throws -> CLLocationCoordinate2D {
    print("getCoordinates called for city: \(city)")
    return try await withCheckedThrowingContinuation { continuation in
      let geocoder = CLGeocoder()
      geocoder.geocodeAddressString(city) { placemarks, error in
        if let coordinate = placemarks?.first?.location?.coordinate {
          print("Geocoding successful. Coordinate: \(coordinate)")
          continuation.resume(returning: coordinate)
        } else {
          print("Geocoding failed for city: \(city). Error: \(String(describing: error))")
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
    let urlString =
      "\(baseURL)?latitude=\(latitude)&longitude=\(longitude)&current=temperature_2m,relative_humidity_2m,apparent_temperature,surface_pressure,precipitation,windspeed_10m,weathercode"

    print("fetchWeatherFromOpenMeteo URL: \(urlString)")

    guard let url = URL(string: urlString) else {
      print("Invalid URL: \(urlString)")
      throw WeatherError.invalidURL
    }

    let (data, response) = try await URLSession.shared.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse,
      httpResponse.statusCode == 200
    else {
      print("API error with response: \(response)")
      throw WeatherError.apiError
    }

    do {
      let openMeteoResponse = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
      let current = openMeteoResponse.current
      print("Decoded OpenMeteoResponse: \(current)")

      let weather = WeatherData(
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
      print("Returning WeatherData: \(weather)")
      return weather
    } catch {
      print("Decoding error: \(error)")
      throw error
    }
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
