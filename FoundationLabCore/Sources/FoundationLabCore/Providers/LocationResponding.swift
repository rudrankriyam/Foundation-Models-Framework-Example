import Foundation

public protocol LocationResponding: Sendable {
    func getCurrentLocation(for request: GetCurrentLocationRequest) async throws -> TextGenerationResult
}
