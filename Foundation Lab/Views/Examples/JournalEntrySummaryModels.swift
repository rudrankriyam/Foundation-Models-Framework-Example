//
//  JournalEntrySummaryModels.swift
//  FoundationLab
//
//  @Generable models for structured journal entry summary generation.
//

import Foundation
import FoundationModels

@Generable
struct JournalEntrySummary {
    @Guide(description: "A gentle journaling prompt inspired by the user's mood, sleep, and any quote or affirmation.")
    let prompt: String

    @Guide(description: "A short, compassionate message that acknowledges the user's mood.")
    let upliftingMessage: String

    @Guide(description: "Short sentence starters that make it easier to begin writing.", .count(2...3))
    let sentenceStarters: [String]

    @Guide(description: "Exactly three bullet points summarizing the entry.", .count(3...3))
    let summaryBullets: [String]

    @Guide(description: "Themes or tags that describe the entry.", .count(3...5))
    let themes: [String]
}
