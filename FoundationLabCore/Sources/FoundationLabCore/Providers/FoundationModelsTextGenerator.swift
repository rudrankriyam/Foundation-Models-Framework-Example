import Foundation
import FoundationModels

public struct FoundationModelsTextGenerator: TextGenerationProviding {
    public init() {}

    public func generateText(for request: TextGenerationRequest) async throws -> TextGenerationResult {
        let prompt = request.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing prompt")
        }

        let model = SystemLanguageModel(
            useCase: request.modelUseCase,
            guardrails: request.guardrails ?? .default
        )
        let session: LanguageModelSession

        if let systemPrompt = request.systemPrompt?.trimmingCharacters(in: .whitespacesAndNewlines),
           !systemPrompt.isEmpty {
            session = LanguageModelSession(
                model: model,
                instructions: Instructions(systemPrompt)
            )
        } else {
            session = LanguageModelSession(model: model)
        }

        let responseContent: String
        if let generationOptions = request.generationOptions {
            responseContent = try await session.respond(
                to: Prompt(prompt),
                options: generationOptions
            ).content
        } else {
            responseContent = try await session.respond(to: Prompt(prompt)).content
        }

        let tokenCount = await session.transcript.foundationLabTokenCount(using: model)

        return TextGenerationResult(
            content: responseContent,
            metadata: CapabilityExecutionMetadata(
                provider: "Foundation Models",
                tokenCount: tokenCount
            )
        )
    }
}
