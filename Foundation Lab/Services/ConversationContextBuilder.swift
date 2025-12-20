//
//  ConversationContextBuilder.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 12/20/25.
//

import Foundation
import FoundationModels

enum ConversationContextBuilder {
    static func conversationText(
        from transcript: Transcript,
        userLabel: String,
        assistantLabel: String
    ) -> String {
        transcript.compactMap { entry in
            switch entry {
            case .prompt:
                guard let text = entry.textContent() else { return nil }
                return "\(userLabel) \(text)"
            case .response:
                guard let text = entry.textContent() else { return nil }
                return "\(assistantLabel) \(text)"
            default:
                return nil
            }
        }.joined(separator: "\n\n")
    }

    static func contextInstructions(
        baseInstructions: String,
        summary: String,
        keyTopics: [String],
        userPreferences: [String],
        continuationNote: String? = nil
    ) -> String {
        var contextInstructions = """
        \(baseInstructions)

        You are continuing a conversation with a user. Here's a summary of your previous conversation:

        CONVERSATION SUMMARY:
        \(summary)

        KEY TOPICS DISCUSSED:
        \(keyTopics.bulletList())

        USER PREFERENCES/REQUESTS:
        \(userPreferences.bulletList())
        """

        if let continuationNote {
            contextInstructions += "\n\n\(continuationNote)"
        }

        return contextInstructions
    }
}
