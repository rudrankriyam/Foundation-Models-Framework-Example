import Foundation
import FoundationModels

public struct RunConversationRequest: CapabilityRequest, Sendable {
    public let prompts: [String]
    public let systemPrompt: String?
    public let modelUseCase: SystemLanguageModel.UseCase
    public let guardrails: SystemLanguageModel.Guardrails?
    public let generationOptions: GenerationOptions?
    public let context: CapabilityInvocationContext

    public init(
        prompts: [String],
        systemPrompt: String? = nil,
        modelUseCase: SystemLanguageModel.UseCase = .general,
        guardrails: SystemLanguageModel.Guardrails? = nil,
        generationOptions: GenerationOptions? = nil,
        context: CapabilityInvocationContext
    ) {
        self.prompts = prompts
        self.systemPrompt = systemPrompt
        self.modelUseCase = modelUseCase
        self.guardrails = guardrails
        self.generationOptions = generationOptions
        self.context = context
    }
}
