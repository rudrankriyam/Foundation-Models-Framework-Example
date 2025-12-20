//
//  InferenceService.swift
//  Foundation Lab
//
//  Created by Rudrank Riyam on 10/27/25.
//

import Foundation
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
    public let session: LanguageModelSession
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
        self.session = LanguageModelSession(instructions: Instructions(instructionsText))
    }

    /// Process text input and return text output
    /// - Parameter text: The input text from speech recognition
    /// - Returns: The response text to be sent to speech synthesis
    func processText(_ text: String) async throws -> String {
        let response = try await session.respond(to: text)
        return response.content
    }

}
