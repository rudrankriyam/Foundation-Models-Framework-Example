//
//  InferenceService.swift
//  Foundation Lab
//
//  Created by Rudrank Riyam on 10/27/25.
//

import Foundation
import FoundationLabCore
import FoundationModels

// MARK: - AI Inference Protocol

/// Protocol defining the interface for AI-powered text processing
@MainActor
protocol InferenceServiceProtocol {
    /// Process input text and return AI-generated response
    /// - Parameter text: Input text from speech recognition
    /// - Returns: Processed text response from AI
    /// - Throws: Error if processing fails
    func processText(_ text: String) async throws -> String
}

// MARK: - AI Inference Service

/// Independent inference service that processes text input and returns text output
/// This service is completely decoupled from speech recognition and synthesis
@MainActor
class InferenceService: InferenceServiceProtocol {
    private let conversationEngine: FoundationLabConversationEngine
    public var session: LanguageModelSession { conversationEngine.session }
    public let instructions: String

    init() {
        let instructionsText = """
        You are a helpful AI assistant for voice conversations.

        CURRENT CONTEXT:
        - Use the user's current locale and time zone when giving time-related responses.

        You can help with:
        - Answering questions on any topic
        - Having natural, friendly conversations
        - Providing explanations and advice
        - Creative tasks like brainstorming and storytelling
        - General productivity assistance
        - Learning and educational support

        Always respond in a conversational, friendly manner. Keep responses concise and natural
        for speech synthesis. Aim for responses that are 1-3 sentences when possible, unless the
        user specifically asks for more detail.
        """

        self.instructions = instructionsText
        self.conversationEngine = FoundationLabConversationEngine(
            configuration: FoundationLabConversationConfiguration(
                baseInstructions: instructionsText,
                summaryInstructions: """
                You are an expert at summarizing voice conversations.
                Preserve the key facts, user goals, and conversational context needed to continue naturally.
                """,
                summaryPromptPreamble: """
                Please summarize the following voice conversation so it can continue naturally in the next turn:
                """,
                conversationUserLabel: "User:",
                conversationAssistantLabel: "Assistant:",
                continuationNote: """
                Continue the voice conversation naturally and keep responses concise for speech synthesis.
                """,
                modelUseCase: .general,
                guardrails: .default,
                enableSlidingWindow: true,
                defaultMaxContextSize: 4_096
            )
        )
    }

    /// Process text input and return text output
    /// - Parameter text: The input text from speech recognition
    /// - Returns: The response text to be sent to speech synthesis
    func processText(_ text: String) async throws -> String {
        try await conversationEngine.sendMessage(text)
    }

}
