import Foundation
import FoundationModels

public struct FoundationModelsBookRecommendationGenerator: BookRecommendationGenerating {
    public init() {}

    public func generateBookRecommendation(
        for request: GenerateBookRecommendationRequest
    ) async throws -> GenerateBookRecommendationResult {
        let trimmedPrompt = request.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing prompt")
        }

        let session: LanguageModelSession
        if let systemPrompt = request.systemPrompt?.trimmingCharacters(in: .whitespacesAndNewlines),
           !systemPrompt.isEmpty {
            session = LanguageModelSession(instructions: Instructions(systemPrompt))
        } else {
            session = LanguageModelSession()
        }

        let response = try await session.respond(
            to: Prompt(trimmedPrompt),
            generating: BookRecommendation.self
        )

        let tokenCount = await session.transcript.foundationLabTokenCount()

        return GenerateBookRecommendationResult(
            recommendation: response.content,
            metadata: CapabilityExecutionMetadata(
                provider: "Foundation Models",
                tokenCount: tokenCount
            )
        )
    }
}
