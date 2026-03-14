import Foundation
import FoundationModels

public struct GetWeatherRequest: CapabilityRequest, Sendable {
    public let location: String
    public let systemPrompt: String?
    public let modelUseCase: SystemLanguageModel.UseCase
    public let guardrails: SystemLanguageModel.Guardrails?
    public let context: CapabilityInvocationContext

    public init(
        location: String,
        systemPrompt: String? = nil,
        modelUseCase: SystemLanguageModel.UseCase = .general,
        guardrails: SystemLanguageModel.Guardrails? = nil,
        context: CapabilityInvocationContext
    ) {
        self.location = location
        self.systemPrompt = systemPrompt
        self.modelUseCase = modelUseCase
        self.guardrails = guardrails
        self.context = context
    }
}
