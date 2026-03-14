import Foundation
import FoundationModels

public struct FoundationLabConversationConfiguration {
    public var baseInstructions: String
    public var summaryInstructions: String
    public var summaryPromptPreamble: String
    public var conversationUserLabel: String
    public var conversationAssistantLabel: String
    public var continuationNote: String
    public var overflowResetMessage: String?
    public var modelUseCase: FoundationLabModelUseCase
    public var guardrails: FoundationLabGuardrails
    public var tools: [any Tool]
    public var enableSlidingWindow: Bool
    public var windowThreshold: Double
    public var targetWindowSize: Int
    public var defaultMaxContextSize: Int

    public init(
        baseInstructions: String,
        summaryInstructions: String,
        summaryPromptPreamble: String,
        conversationUserLabel: String,
        conversationAssistantLabel: String,
        continuationNote: String,
        overflowResetMessage: String? = nil,
        modelUseCase: FoundationLabModelUseCase = .general,
        guardrails: FoundationLabGuardrails = .default,
        tools: [any Tool] = [],
        enableSlidingWindow: Bool = false,
        windowThreshold: Double = 0.70,
        targetWindowSize: Int = 6_000,
        defaultMaxContextSize: Int = 4_096
    ) {
        self.baseInstructions = baseInstructions
        self.summaryInstructions = summaryInstructions
        self.summaryPromptPreamble = summaryPromptPreamble
        self.conversationUserLabel = conversationUserLabel
        self.conversationAssistantLabel = conversationAssistantLabel
        self.continuationNote = continuationNote
        self.overflowResetMessage = overflowResetMessage
        self.modelUseCase = modelUseCase
        self.guardrails = guardrails
        self.tools = tools
        self.enableSlidingWindow = enableSlidingWindow
        self.windowThreshold = windowThreshold
        self.targetWindowSize = targetWindowSize
        self.defaultMaxContextSize = defaultMaxContextSize
    }
}
