import Foundation
import FoundationModels

public struct FoundationModelsConversationRunner: ConversationRunning {
    public init() {}

    public func runConversation(for request: RunConversationRequest) async throws -> RunConversationResult {
        let prompts = request.prompts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !prompts.isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing prompts")
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

        var exchanges: [ConversationExchange] = []

        for prompt in prompts {
            do {
                let responseContent: String
                if let generationOptions = request.generationOptions {
                    responseContent = try await session.respond(
                        to: Prompt(prompt),
                        options: generationOptions
                    ).content
                } else {
                    responseContent = try await session.respond(to: Prompt(prompt)).content
                }

                exchanges.append(
                    ConversationExchange(
                        prompt: prompt,
                        response: responseContent,
                        isError: false
                    )
                )
            } catch {
                exchanges.append(
                    ConversationExchange(
                        prompt: prompt,
                        response: error.localizedDescription,
                        isError: true
                    )
                )
            }
        }

        let tokenCount = await session.transcript.foundationLabTokenCount(using: model)

        return RunConversationResult(
            exchanges: exchanges,
            metadata: CapabilityExecutionMetadata(
                provider: "Foundation Models",
                tokenCount: tokenCount
            )
        )
    }
}
