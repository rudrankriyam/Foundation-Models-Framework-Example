import Foundation
import FoundationModels
import FoundationModelsKit

public struct FoundationModelsDynamicSchemaGenerator: DynamicSchemaGenerationProviding {
    public init() {}

    public func generate(for request: DynamicSchemaGenerationRequest) async throws -> DynamicSchemaGenerationResult {
        let prompt = request.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing prompt")
        }

        let model = try FoundationModelsModelFactory.makeModel(
            useCase: request.modelUseCase,
            guardrails: request.guardrails ?? .default,
            adapterURL: request.adapterURL
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
                includeSchemaInPrompt: request.includeSchemaInPrompt,
                options: generationOptions.foundationModelsValue
            ).content
        } else {
            output = try await session.respond(
                to: Prompt(prompt),
                schema: request.schema,
                includeSchemaInPrompt: request.includeSchemaInPrompt
            ).content
        }

        let tokenCount = await session.transcript.tokenCount(using: model)

        return DynamicSchemaGenerationResult(
            output: output,
            metadata: CapabilityExecutionMetadata(
                provider: "Foundation Models",
                modelIdentifier: request.adapterURL?.lastPathComponent ?? request.modelUseCase.rawValue,
                tokenCount: tokenCount
            )
        )
    }
}
