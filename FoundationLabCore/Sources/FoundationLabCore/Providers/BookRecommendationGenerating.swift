import Foundation

public protocol BookRecommendationGenerating: Sendable {
    func generateBookRecommendation(
        for request: GenerateBookRecommendationRequest
    ) async throws -> GenerateBookRecommendationResult
}
