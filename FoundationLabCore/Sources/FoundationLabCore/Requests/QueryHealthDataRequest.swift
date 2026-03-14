import Foundation
import FoundationModels

public struct QueryHealthDataRequest: CapabilityRequest, Sendable {
    public let query: String
    public let systemPrompt: String?
    public let modelUseCase: SystemLanguageModel.UseCase
    public let guardrails: SystemLanguageModel.Guardrails?
    public let referenceDate: Date
    public let timeZoneIdentifier: String
    public let context: CapabilityInvocationContext

    public init(
        query: String,
        systemPrompt: String? = nil,
        modelUseCase: SystemLanguageModel.UseCase = .general,
        guardrails: SystemLanguageModel.Guardrails? = nil,
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
