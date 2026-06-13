import Foundation
import FoundationModels
import FoundationModelsKit

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

        let response: LanguageModelSession.Response<Output>
        if let generationOptions = request.generationOptions {
            response = try await session.respond(
                to: Prompt(prompt),
                generating: type,
                includeSchemaInPrompt: request.includeSchemaInPrompt,
                options: generationOptions.foundationModelsValue
            )
        } else {
            response = try await session.respond(
                to: Prompt(prompt),
                generating: type,
                includeSchemaInPrompt: request.includeSchemaInPrompt
            )
        }

        let tokenCount = await session.transcript.tokenCount(using: model)

        return StructuredGenerationResult(
            output: response.content,
            metadata: CapabilityExecutionMetadata(
                provider: "Foundation Models",
                modelIdentifier: request.adapterURL?.lastPathComponent ?? request.modelUseCase.rawValue,
                tokenCount: tokenCount
            )
        )
    }
}
