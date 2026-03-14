import Foundation

public protocol HealthEncouragementGenerating: Sendable {
    func generateHealthEncouragement(
        for request: GenerateHealthEncouragementRequest
    ) async throws -> GenerateHealthEncouragementResult
}
