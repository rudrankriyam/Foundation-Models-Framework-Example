import Foundation
import FoundationModels

public struct GenerateWebPageSummaryRequest: CapabilityRequest, Sendable {
    public let url: String
    public let systemPrompt: String?
    public let modelUseCase: SystemLanguageModel.UseCase
    public let guardrails: SystemLanguageModel.Guardrails?
    public let context: CapabilityInvocationContext

    public init(
        url: String,
        systemPrompt: String? = nil,
        modelUseCase: SystemLanguageModel.UseCase = .general,
        guardrails: SystemLanguageModel.Guardrails? = nil,
        context: CapabilityInvocationContext
    ) {
        self.url = url
        self.systemPrompt = systemPrompt
        self.modelUseCase = modelUseCase
        self.guardrails = guardrails
        self.context = context
    }
}
