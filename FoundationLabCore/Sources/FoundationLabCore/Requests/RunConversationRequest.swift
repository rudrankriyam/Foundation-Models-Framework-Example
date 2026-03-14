import Foundation
public struct RunConversationRequest: CapabilityRequest, Sendable {
    public let prompts: [String]
    public let systemPrompt: String?
    public let modelUseCase: FoundationLabModelUseCase
    public let guardrails: FoundationLabGuardrails?
    public let generationOptions: FoundationLabGenerationOptions?
    public let context: CapabilityInvocationContext

    public init(
        prompts: [String],
        systemPrompt: String? = nil,
        modelUseCase: FoundationLabModelUseCase = .general,
        guardrails: FoundationLabGuardrails? = nil,
        generationOptions: FoundationLabGenerationOptions? = nil,
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
