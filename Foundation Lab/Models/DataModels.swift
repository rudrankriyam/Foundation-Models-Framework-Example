//
//  DataModels.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/9/25.
//

import Foundation
import FoundationModels

// MARK: - Chat Models

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let entryID: Transcript.Entry.ID?
    let content: AttributedString
    let isFromUser: Bool
    let timestamp: Date
    let isContextSummary: Bool

    init(content: String, isFromUser: Bool, isContextSummary: Bool = false) {
        self.init(entryID: nil, content: content, isFromUser: isFromUser, isContextSummary: isContextSummary)
    }

    init(entryID: Transcript.Entry.ID?, content: String, isFromUser: Bool, isContextSummary: Bool = false) {
        self.id = UUID()
        self.entryID = entryID
        self.content = AttributedString(content)
        self.isFromUser = isFromUser
        self.timestamp = Date()
        self.isContextSummary = isContextSummary
    }

    init(content: AttributedString, isFromUser: Bool, isContextSummary: Bool = false) {
        self.init(id: UUID(), content: content, isFromUser: isFromUser,
                 timestamp: Date(), isContextSummary: isContextSummary)
    }

    init(id: UUID, content: String, isFromUser: Bool, timestamp: Date, isContextSummary: Bool = false) {
        self.init(id: id, content: AttributedString(content), isFromUser: isFromUser,
                 timestamp: timestamp, isContextSummary: isContextSummary)
    }

    init(id: UUID, content: AttributedString, isFromUser: Bool, timestamp: Date, isContextSummary: Bool = false) {
        self.id = id
        self.entryID = nil
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        self.isContextSummary = isContextSummary
    }
}

@Generable
struct ConversationSummary {
    @Guide(
        description:
            "A comprehensive summary of the entire conversation including all key points, topics discussed, " +
            "questions asked, and responses provided. Include important context and details that would help " +
            "continue the conversation naturally."
    )
    let summary: String

    @Guide(description: "The main topics or themes that were discussed in the conversation")
    let keyTopics: [String]

    @Guide(
        description: "Any specific requests, preferences, or important information the user mentioned")
    let userPreferences: [String]
}

// MARK: - Request/Response Models

struct RequestResponsePair: Identifiable {
    let id = UUID()
    let request: String
    let response: String
    let isError: Bool
    let timestamp: Date

    init(request: String, response: String, isError: Bool = false) {
        self.request = request
        self.response = response
        self.isError = isError
        self.timestamp = Date()
    }
}
