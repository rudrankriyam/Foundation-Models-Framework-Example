import Foundation
import FoundationModels

public struct FoundationModelsDynamicSchemaGenerator: DynamicSchemaGenerationProviding {
    public init() {}

    public func generate(for request: DynamicSchemaGenerationRequest) async throws -> DynamicSchemaGenerationResult {
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

        let output: GeneratedContent
        if let generationOptions = request.generationOptions {
            output = try await session.respond(
                to: Prompt(prompt),
                schema: request.schema,
                options: generationOptions.foundationModelsValue
            ).content
        } else {
            output = try await session.respond(
                to: Prompt(prompt),
                schema: request.schema
            ).content
        }

        let tokenCount = await session.transcript.foundationLabTokenCount(using: model)

        return DynamicSchemaGenerationResult(
            output: output,
            metadata: CapabilityExecutionMetadata(
                provider: "Foundation Models",
                tokenCount: tokenCount
            )
        )
    }
}
