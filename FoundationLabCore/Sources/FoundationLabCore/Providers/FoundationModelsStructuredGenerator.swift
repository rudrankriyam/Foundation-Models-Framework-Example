import Foundation
import FoundationModels

public struct FoundationModelsStructuredGenerator: StructuredGenerationProviding {
    public init() {}

    public func generate<Output: Generable & Sendable>(
        _ type: Output.Type,
        for request: StructuredGenerationRequest<Output>
    ) async throws -> StructuredGenerationResult<Output> {
        let prompt = request.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing prompt")
        }

        let model = SystemLanguageModel(
            useCase: request.modelUseCase.foundationModelsValue,
            guardrails: (request.guardrails ?? FoundationLabGuardrails.default).foundationModelsValue
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

        let response = try await session.respond(
            to: Prompt(prompt),
            generating: type
        )

        let tokenCount = await session.transcript.foundationLabTokenCount(using: model)

        return StructuredGenerationResult(
            output: response.content,
            metadata: CapabilityExecutionMetadata(
                provider: "Foundation Models",
                tokenCount: tokenCount
            )
        )
    }
}
