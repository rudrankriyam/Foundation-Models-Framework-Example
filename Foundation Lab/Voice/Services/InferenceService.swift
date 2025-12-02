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

    init() {
        let instructions = """
        You are a helpful AI assistant for voice conversations.

        CURRENT CONTEXT:
        - Today's date is: \(Self.formatCurrentDate())
        - Current time is: \(Self.formatCurrentTime())
        - Current timezone: \(Self.formatCurrentTimezone())

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

        self.session = LanguageModelSession(
            instructions: Instructions(instructions)
        )
    }

    /// Process text input and return text output
    /// - Parameter text: The input text from speech recognition
    /// - Returns: The response text to be sent to speech synthesis
    func processText(_ text: String) async throws -> String {
        let response = try await session.respond(to: text)
        return response.content
    }

    // MARK: - Date Formatting Utilities

    private static func formatCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: Date())
    }

    private static func formatCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: Date())
    }

    private static func formatCurrentTimezone() -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "zzz"
        return formatter.string(from: Date())
    }
}
