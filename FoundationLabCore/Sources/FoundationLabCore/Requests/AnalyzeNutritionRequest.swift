import Foundation

public struct AnalyzeNutritionRequest: CapabilityRequest, Sendable, Hashable, Codable {
    public let foodDescription: String
    public let responseLanguage: String
    public let guardrails: FoundationLabGuardrails?
    public let context: CapabilityInvocationContext

    public init(
        foodDescription: String,
        responseLanguage: String,
        guardrails: FoundationLabGuardrails? = nil,
        context: CapabilityInvocationContext
    ) {
        self.foodDescription = foodDescription
        self.responseLanguage = responseLanguage
        self.guardrails = guardrails
        self.context = context
    }
}
