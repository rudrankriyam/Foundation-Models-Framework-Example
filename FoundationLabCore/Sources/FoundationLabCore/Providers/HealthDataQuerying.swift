import Foundation

public protocol HealthDataQuerying: Sendable {
    func queryHealthData(for request: QueryHealthDataRequest) async throws -> TextGenerationResult
}
