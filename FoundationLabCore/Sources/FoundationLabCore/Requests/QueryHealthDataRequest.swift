import Foundation
public struct QueryHealthDataRequest: CapabilityRequest, Sendable {
    public let query: String
    public let systemPrompt: String?
    public let modelUseCase: FoundationLabModelUseCase
    public let guardrails: FoundationLabGuardrails?
    public let referenceDate: Date
    public let timeZoneIdentifier: String
    public let context: CapabilityInvocationContext

    public init(
        query: String,
        systemPrompt: String? = nil,
        modelUseCase: FoundationLabModelUseCase = .general,
        guardrails: FoundationLabGuardrails? = nil,
        referenceDate: Date = .now,
        timeZoneIdentifier: String = TimeZone.current.identifier,
        context: CapabilityInvocationContext
    ) {
        self.query = query
        self.systemPrompt = systemPrompt
        self.modelUseCase = modelUseCase
        self.guardrails = guardrails
        self.referenceDate = referenceDate
        self.timeZoneIdentifier = timeZoneIdentifier
        self.context = context
    }
}
