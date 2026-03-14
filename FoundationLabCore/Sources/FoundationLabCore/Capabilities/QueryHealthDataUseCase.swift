import Foundation

public struct QueryHealthDataUseCase: CapabilityUseCase {
    public static let descriptor = CapabilityDescriptor(
        id: "foundation-models.query-health-data",
        displayName: "Query Health Data",
        summary: "Queries HealthKit-backed data using shared Foundation Models orchestration."
    )

    private let querier: any HealthDataQuerying

    public init(querier: any HealthDataQuerying = FoundationModelsHealthDataQuerier()) {
        self.querier = querier
    }

    public func execute(_ request: QueryHealthDataRequest) async throws -> TextGenerationResult {
        let query = request.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing query")
        }

        return try await querier.queryHealthData(for: request)
    }
}
