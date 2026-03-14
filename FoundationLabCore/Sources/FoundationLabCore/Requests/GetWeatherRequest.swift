import Foundation
public struct GetWeatherRequest: CapabilityRequest, Sendable {
    public let location: String
    public let systemPrompt: String?
    public let modelUseCase: FoundationLabModelUseCase
    public let guardrails: FoundationLabGuardrails?
    public let context: CapabilityInvocationContext

    public init(
        location: String,
        systemPrompt: String? = nil,
        modelUseCase: FoundationLabModelUseCase = .general,
        guardrails: FoundationLabGuardrails? = nil,
        context: CapabilityInvocationContext
    ) {
        self.location = location
        self.systemPrompt = systemPrompt
        self.modelUseCase = modelUseCase
        self.guardrails = guardrails
        self.context = context
    }
}
