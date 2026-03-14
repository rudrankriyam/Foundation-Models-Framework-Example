import Foundation
import FoundationModels

public struct GetCurrentLocationRequest: CapabilityRequest, Sendable {
    public let systemPrompt: String?
    public let modelUseCase: SystemLanguageModel.UseCase
    public let guardrails: SystemLanguageModel.Guardrails?
    public let context: CapabilityInvocationContext

    public init(
        systemPrompt: String? = nil,
        modelUseCase: SystemLanguageModel.UseCase = .general,
        guardrails: SystemLanguageModel.Guardrails? = nil,
        context: CapabilityInvocationContext
    ) {
        self.systemPrompt = systemPrompt
        self.modelUseCase = modelUseCase
        self.guardrails = guardrails
        self.context = context
    }
}
