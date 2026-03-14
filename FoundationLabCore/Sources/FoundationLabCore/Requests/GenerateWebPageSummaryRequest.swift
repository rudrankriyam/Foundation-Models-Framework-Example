import Foundation
public struct GenerateWebPageSummaryRequest: CapabilityRequest, Sendable {
    public let url: String
    public let systemPrompt: String?
    public let modelUseCase: FoundationLabModelUseCase
    public let guardrails: FoundationLabGuardrails?
    public let context: CapabilityInvocationContext

    public init(
        url: String,
        systemPrompt: String? = nil,
        modelUseCase: FoundationLabModelUseCase = .general,
        guardrails: FoundationLabGuardrails? = nil,
        context: CapabilityInvocationContext
    ) {
        self.url = url
        self.systemPrompt = systemPrompt
        self.modelUseCase = modelUseCase
        self.guardrails = guardrails
        self.context = context
    }
}
