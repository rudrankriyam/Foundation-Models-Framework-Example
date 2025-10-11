//
//  ConversationSummary.swift
//  Physiqa
//
//  Created by Rudrank Riyam on 6/23/25.
//

import Foundation
import FoundationModels

@Generable
struct ConversationSummary {
    @Guide(description: "A comprehensive summary of the health coaching conversation")
    let summary: String

    @Guide(description: "Key health topics and metrics discussed in the conversation")
    let keyTopics: [String]

    @Guide(description: "User's health goals, preferences, and concerns mentioned")
    let userPreferences: [String]

    @Guide(description: "Important health advice or recommendations given")
    let healthAdvice: [String]

    @Guide(description: "Any health metrics or data points mentioned")
    let healthMetrics: [String]
}
