import Foundation
public struct SearchContactsRequest: CapabilityRequest, Sendable {
    public let query: String
    public let systemPrompt: String?
    public let modelUseCase: FoundationLabModelUseCase
    public let guardrails: FoundationLabGuardrails?
    public let context: CapabilityInvocationContext

    public init(
        query: String,
        systemPrompt: String? = nil,
        modelUseCase: FoundationLabModelUseCase = .general,
        guardrails: FoundationLabGuardrails? = nil,
        context: CapabilityInvocationContext
    ) {
        self.query = query
        self.systemPrompt = systemPrompt
        self.modelUseCase = modelUseCase
        self.guardrails = guardrails
        self.context = context
    }
}
