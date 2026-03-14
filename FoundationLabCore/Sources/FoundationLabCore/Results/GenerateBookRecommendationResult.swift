import Foundation

public struct GenerateBookRecommendationResult: CapabilityResult, Sendable, Hashable, Codable {
    public let recommendation: BookRecommendation
    public let metadata: CapabilityExecutionMetadata

    public init(
        recommendation: BookRecommendation,
        metadata: CapabilityExecutionMetadata = CapabilityExecutionMetadata()
    ) {
        self.recommendation = recommendation
        self.metadata = metadata
    }
}
