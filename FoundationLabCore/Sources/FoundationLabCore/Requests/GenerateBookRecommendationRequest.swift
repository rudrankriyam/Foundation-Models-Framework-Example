import Foundation

public struct GenerateBookRecommendationRequest: CapabilityRequest, Sendable, Hashable, Codable {
    public let prompt: String
    public let systemPrompt: String?
    public let context: CapabilityInvocationContext

    public init(
        prompt: String,
        systemPrompt: String? = nil,
        context: CapabilityInvocationContext
    ) {
        self.prompt = prompt
        self.systemPrompt = systemPrompt
        self.context = context
    }
}
