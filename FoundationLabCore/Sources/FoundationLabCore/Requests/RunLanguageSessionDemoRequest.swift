import Foundation

public struct RunLanguageSessionDemoRequest: CapabilityRequest {
    public let steps: [LanguageConversationStep]
    public let systemPrompt: String?
    public let context: CapabilityInvocationContext

    public init(
        steps: [LanguageConversationStep] = FoundationLabLanguageCatalog.defaultConversationSteps,
        systemPrompt: String? = FoundationLabLanguageCatalog.multilingualSystemPrompt,
        context: CapabilityInvocationContext
    ) {
        self.steps = steps
        self.systemPrompt = systemPrompt
        self.context = context
    }
}
