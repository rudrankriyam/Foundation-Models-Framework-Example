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
    self.init(id: UUID(), content: content, isFromUser: isFromUser, timestamp: Date(), isContextSummary: isContextSummary)
  }

  init(id: UUID, content: String, isFromUser: Bool, timestamp: Date, isContextSummary: Bool = false) {
    self.init(id: id, content: AttributedString(content), isFromUser: isFromUser, timestamp: timestamp, isContextSummary: isContextSummary)
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
      "A comprehensive summary of the entire conversation including all key points, topics discussed, questions asked, and responses provided. Include important context and details that would help continue the conversation naturally."
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

// MARK: - Book Recommendation Models

@Generable
struct BookRecommendation {
  @Guide(description: "The title of the book")
  let title: String

  @Guide(description: "The author's name")
  let author: String

  @Guide(description: "A brief description in 2-3 sentences")
  let description: String

  @Guide(description: "Genre of the book")
  let genre: Genre
}

@Generable
enum Genre {
  case fiction
  case nonFiction
  case mystery
  case romance
  case sciFi
  case fantasy
  case biography
  case history
}

// MARK: - Product Review Models

@Generable
struct ProductReview {
  @Guide(description: "Product name")
  let productName: String

  @Guide(description: "Rating from 1 to 5")
  let rating: Int

  @Guide(description: "Review text between 50-200 words")
  let reviewText: String

  @Guide(description: "Would recommend this product")
  let recommendation: String

  @Guide(description: "Key pros of the product")
  let pros: [String]

  @Guide(description: "Key cons of the product")
  let cons: [String]
}

// MARK: - Creative Writing Models

@Generable
struct StoryOutline {
  @Guide(description: "The title of the story")
  let title: String

  @Guide(description: "Main character name and brief description")
  let protagonist: String

  @Guide(description: "The central conflict or challenge")
  let conflict: String

  @Guide(description: "The setting where the story takes place")
  let setting: String

  @Guide(description: "Story genre")
  let genre: StoryGenre

  @Guide(description: "Major themes explored in the story")
  let themes: [String]
}

@Generable
enum StoryGenre {
  case adventure
  case mystery
  case romance
  case thriller
  case fantasy
  case sciFi
  case horror
  case comedy
}

// MARK: - Business Models

@Generable
struct BusinessIdea {
  @Guide(description: "Name of the business")
  let name: String

  @Guide(description: "Brief description of what the business does")
  let description: String

  @Guide(description: "Target market or customer base")
  let targetMarket: String

  @Guide(description: "Primary revenue model")
  let revenueModel: String

  @Guide(description: "Key advantages or unique selling points")
  let advantages: [String]

  @Guide(description: "Initial startup costs estimate")
  let estimatedStartupCost: String

  @Guide(description: "Expected timeline or phases for launch and growth")
  let timeline: String?
}

@available(iOS 26.1, macOS 26.1, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@Generable
struct BusinessIdeaOptionalSemantics {
  @Guide(description: "Name of the business")
  let name: String

  @Guide(description: "Brief description of what the business does")
  let description: String

  @Guide(description: "Target market or customer base")
  let targetMarket: String

  @Guide(description: "Primary revenue model")
  let revenueModel: String

  @Guide(description: "Key advantages or unique selling points")
  let advantages: [String]

  @Guide(description: "Initial startup costs estimate")
  let estimatedStartupCost: String

  @Guide(description: "Expected timeline or phases for launch and growth", semantics: .possiblyAbsent)
  let timeline: String?
}

@available(iOS 26.1, macOS 26.1, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@Generable
struct EnterpriseExpansionPlan {
  @Guide(description: "Primary region targeted for expansion", semantics: .possiblyNull)
  let region: String?

  @Guide(description: "Projected marketing investment in USD", semantics: .possiblyNull)
  let marketingBudget: String?

  @Guide(description: "Planned engineering headcount for the launch", semantics: .possiblyNull)
  let engineeringHeadcount: String?

  @Guide(description: "Quarterly revenue expectations", semantics: .possiblyNull)
  let revenueTargets: String?

  @Guide(description: "Strategic partnerships to secure", semantics: .possiblyNull)
  let partnerships: [String]?

  @Guide(description: "Key compliance milestones", semantics: .possiblyNull)
  let complianceStatus: [String]?

  @Guide(description: "Identified risks and mitigation plans", semantics: .possiblyNull)
  let riskAssessment: [String]?

  @Guide(description: "Infrastructure or tooling upgrades required", semantics: .possiblyNull)
  let infrastructureNeeds: [String]?

  @Guide(description: "Localization status for product and support", semantics: .possiblyNull)
  let localizationStatus: [String]?

  @Guide(description: "Customer support readiness milestones", semantics: .possiblyNull)
  let supportStrategy: [String]?

  @Guide(description: "Training material requirements", semantics: .possiblyNull)
  let trainingPlan: [String]?

  @Guide(description: "Dependencies that could delay launch", semantics: .possiblyNull)
  let launchDependencies: [String]?
}
