//
//  InferenceService.swift
//  Murmer
//
//  Created by Rudrank Riyam on 9/24/25.
//

import Foundation
import FoundationModels
import Playgrounds

/// Independent inference service that processes text input and returns text output
/// This service is completely decoupled from speech recognition and synthesis
class InferenceService {
    public let session: LanguageModelSession
    
    init() {
        let instructions = """
        You are a helpful AI assistant for managing reminders through voice commands.
        
        CURRENT CONTEXT:
        - Today's date is: \(Self.formatCurrentDate())
        - Current time is: \(Self.formatCurrentTime())
        
        When users ask you to create reminders, use the createReminder tool with these guidelines:
        
        TIME PARSING RULES:
        - Parse any time expressions from the user's request (tomorrow, next week, at 3pm, etc.)
        - Convert relative dates using today's date as reference
        - If a time expression is found, provide the dueDate parameter in ISO8601 format
        - If no time is specified, omit the dueDate parameter
        - Clean up the reminder text by removing time expressions from the title
        
        EXAMPLES:
        - "Remind me to call mom tomorrow" → text: "call mom", dueDate: tomorrow's ISO8601 date
        - "Buy groceries" → text: "Buy groceries", dueDate: nil
        - "Meeting at 3pm today" → text: "Meeting", dueDate: today at 3pm in ISO8601
        
        Always respond in a conversational, helpful manner and confirm what you've done.
        """
        
        self.session = LanguageModelSession(
            tools: [MurmerRemindersTool()],
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
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: Date())
    }
    
    private static func formatCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: Date())
    }
}

#Playground {
    Task {
        do {
            let service = InferenceService()
            let text = try await service.processText("Pay the credit card bill tomorrow morning")
            debugPrint(service.session.transcript)
        } catch {
            debugPrint(" An error occurred: \(error)")
        }
    }
}
