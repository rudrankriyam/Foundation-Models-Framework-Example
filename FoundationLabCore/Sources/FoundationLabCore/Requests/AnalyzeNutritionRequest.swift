import Foundation

public struct AnalyzeNutritionRequest: CapabilityRequest, Sendable, Hashable, Codable {
    public let foodDescription: String
    public let responseLanguage: String
    public let context: CapabilityInvocationContext

    public init(
        foodDescription: String,
        responseLanguage: String,
        context: CapabilityInvocationContext
    ) {
        self.foodDescription = foodDescription
        self.responseLanguage = responseLanguage
        self.context = context
    }
}
