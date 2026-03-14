import Foundation
import FoundationModels

public struct FoundationModelsToolInvoker: Sendable {
    public init() {}

    public func respond<ToolType: Tool>(
        to prompt: String,
        using tool: ToolType,
        systemPrompt: String? = nil,
        modelUseCase: FoundationLabModelUseCase = .general,
        guardrails: FoundationLabGuardrails? = nil,
        generationOptions: FoundationLabGenerationOptions? = nil
    ) async throws -> TextGenerationResult {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing prompt")
        }

        let model = SystemLanguageModel(
            useCase: modelUseCase.foundationModelsValue,
            guardrails: (guardrails ?? FoundationLabGuardrails.default).foundationModelsValue
        )
        let session: LanguageModelSession

        if let systemPrompt = systemPrompt?.trimmingCharacters(in: .whitespacesAndNewlines),
           !systemPrompt.isEmpty {
            session = LanguageModelSession(
                model: model,
                tools: [tool],
                instructions: Instructions(systemPrompt)
            )
        } else {
            session = LanguageModelSession(model: model, tools: [tool])
        }

        let responseContent: String
        if let generationOptions {
            responseContent = try await session.respond(
                to: Prompt(trimmedPrompt),
                options: generationOptions.foundationModelsValue
            ).content
        } else {
            responseContent = try await session.respond(to: Prompt(trimmedPrompt)).content
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
