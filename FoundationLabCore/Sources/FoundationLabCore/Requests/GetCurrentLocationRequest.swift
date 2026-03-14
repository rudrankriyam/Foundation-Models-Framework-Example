import Foundation
public struct GetCurrentLocationRequest: CapabilityRequest, Sendable {
    public let systemPrompt: String?
    public let modelUseCase: FoundationLabModelUseCase
    public let guardrails: FoundationLabGuardrails?
    public let context: CapabilityInvocationContext

    public init(
        systemPrompt: String? = nil,
        modelUseCase: FoundationLabModelUseCase = .general,
        guardrails: FoundationLabGuardrails? = nil,
        context: CapabilityInvocationContext
    ) {
        self.systemPrompt = systemPrompt
        self.modelUseCase = modelUseCase
        self.guardrails = guardrails
        self.context = context
    }
}
