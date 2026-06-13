import Foundation
import FoundationModels
import FoundationModelsKit

public struct FoundationModelsStreamingTextGenerator: StreamingTextGenerationProviding {
    public init() {}

    public func streamText(
        for request: StreamingTextGenerationRequest,
        onPartialResponse: @escaping @Sendable (String) async -> Void
    ) async throws -> TextGenerationResult {
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

        var finalContent = ""
        if let generationOptions = request.generationOptions {
            for try await partialResponse in session.streamResponse(
                to: Prompt(prompt),
                options: generationOptions.foundationModelsValue
            ) {
                finalContent = partialResponse.content
                await onPartialResponse(partialResponse.content)
            }
        } else {
            for try await partialResponse in session.streamResponse(to: Prompt(prompt)) {
                finalContent = partialResponse.content
                await onPartialResponse(partialResponse.content)
            }
        }

        let tokenCount = await session.transcript.tokenCount(using: model)

        return TextGenerationResult(
            content: finalContent,
            metadata: CapabilityExecutionMetadata(
                provider: "Foundation Models",
                modelIdentifier: request.adapterURL?.lastPathComponent ?? request.modelUseCase.rawValue,
                tokenCount: tokenCount
            )
        )
    }
}
