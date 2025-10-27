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
@Observable
@MainActor
class InferenceService: InferenceServiceProtocol {
    public let session: LanguageModelSession

    init() {
        let instructions = """
        You are a helpful AI assistant for managing reminders through voice commands.

        CURRENT CONTEXT:
        - Today's date is: \(Self.formatCurrentDate())
        - Current time is: \(Self.formatCurrentTime())
        - Current timezone: \(Self.formatCurrentTimezone())
        - All times should be interpreted in the user's local timezone: \(TimeZone.current.identifier)

        When users ask you to create reminders, use the createReminder tool with these guidelines:

        TIME PARSING RULES:
        - Parse any time expressions from the user's request (tomorrow, next week, at 3pm, etc.)
        - ALWAYS interpret times in the user's LOCAL TIMEZONE: \(TimeZone.current.identifier)
        - Convert relative dates using today's date as reference
        - If a time expression is found, provide the dueDate parameter in ISO8601 format WITH timezone info
        - Use format: YYYY-MM-DDTHH:mm:ssZ (where Z indicates the timezone offset)
        - If no time is specified, omit the dueDate parameter
        - Clean up the reminder text by removing time expressions from the title

        CRITICAL TIMEZONE RULES:
        - "tomorrow morning" means 9:00 AM tomorrow in \(TimeZone.current.identifier) timezone
        - "at 3pm" means 3:00 PM today in \(TimeZone.current.identifier) timezone
        - Always include timezone offset in ISO8601 dates (e.g., +05:30 for IST, -08:00 for PST)

        EXAMPLES:
        - "Remind me to call mom tomorrow" → text: "call mom",
          dueDate: "2025-09-25T09:00:00\(Self.getTimezoneOffsetString())"
        - "Buy groceries" → text: "Buy groceries", dueDate: nil
        - "Meeting at 3pm today" → text: "Meeting",
          dueDate: "\(Self.getTodayDateString())T15:00:00\(Self.getTimezoneOffsetString())"

        Always respond in a conversational, helpful manner and confirm what you've done.
        """

        self.session = LanguageModelSession(
            tools: [VoiceRemindersTool()],
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

    static func getTimezoneOffsetString() -> String {
        let seconds = TimeZone.current.secondsFromGMT()
        let hours = seconds / 3600
        let minutes = abs(seconds % 3600) / 60

        if minutes == 0 {
            return String(format: "%+03d:00", hours)
        } else {
            return String(format: "%+03d:%02d", hours, minutes)
        }
    }

    private static func getTodayDateString() -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}