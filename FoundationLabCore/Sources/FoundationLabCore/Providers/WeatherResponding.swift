import Foundation

public protocol WeatherResponding: Sendable {
    func weather(for request: GetWeatherRequest) async throws -> TextGenerationResult
}
