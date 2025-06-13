//
//  ContentViewModel.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/9/25.
//

import CoreLocation
import Foundation
import FoundationModels
import MapKit
import Observation
import SwiftUI

/// ViewModel for managing ContentView state and operations
@Observable
final class ContentViewModel {

  // MARK: - Published Properties

  var response: String = ""
  var isLoading: Bool = false
  var errorMessage: String = ""

  // MARK: - Computed Properties

  var hasContent: Bool {
    !response.isEmpty || !errorMessage.isEmpty
  }

  var displayText: String {
    errorMessage.isEmpty ? response : errorMessage
  }

  var isError: Bool {
    !errorMessage.isEmpty
  }

  // MARK: - Example Operations

  @MainActor
  func executeBasicChat() async {
    isLoading = true
    response = ""
    errorMessage = ""

    do {
      // Create a basic session
      let session = LanguageModelSession(instructions: Instructions("You are a helpful assistant."))

      // Generate response
      let response = try await session.respond(
        to: Prompt("Suggest a catchy name for a new coffee shop."))

      self.response = response.content
    } catch {
      errorMessage = handleFoundationModelsError(error)
    }

    isLoading = false
  }

  @MainActor
  func executeStructuredData() async {
    isLoading = true
    response = ""
    errorMessage = ""

    do {
      // Create a basic session
      let session = LanguageModelSession()

      // Generate structured data
      let response = try await session.respond(
        to: Prompt("Suggest a sci-fi book."),
        generating: BookRecommendation.self
      )

      let bookInfo = response.content

      self.response = """
        Title: \(bookInfo.title)
        Author: \(bookInfo.author)
        Genre: \(bookInfo.genre)
        Description: \(bookInfo.description)
        """
    } catch {
      errorMessage = handleFoundationModelsError(error)
    }

    isLoading = false
  }

  @MainActor
  func executeGenerationGuides() async {
    isLoading = true
    response = ""
    errorMessage = ""

    do {
      // Create a basic session
      let session = LanguageModelSession()

      // Generate structured product review
      let response = try await session.respond(
        to: Prompt("Write a product review for a smartphone."),
        generating: ProductReview.self
      )

      let review = response.content

      self.response = """
        Product: \(review.productName)
        Rating: \(review.rating)/5
        Review: \(review.reviewText)
        Recommendation: \(review.recommendation)

        Pros: \(review.pros.joined(separator: ", "))
        Cons: \(review.cons.joined(separator: ", "))
        """
    } catch {
      errorMessage = handleFoundationModelsError(error)
    }

    isLoading = false
  }

  @MainActor
  func executeStreaming() async {
    isLoading = true
    response = ""
    errorMessage = ""

    do {
      // Create a basic session
      let session = LanguageModelSession()

      // Create streaming response
      let stream = session.streamResponse(to: Prompt("Write a short poem about technology."))

      // Process streaming updates
      for try await partialResponse in stream {
        self.response = partialResponse
      }

      // Get final response
      let finalResponse = try await stream.collect()
      self.response = finalResponse.content
      isLoading = false
    } catch {
      errorMessage = handleFoundationModelsError(error)
      isLoading = false
    }
  }

  @MainActor
  func executeModelAvailability() async {
    isLoading = true
    response = ""
    errorMessage = ""

    // Check model availability
    let model = SystemLanguageModel.default
    let contentTaggingModel = SystemLanguageModel(useCase: .contentTagging)

    var result = "Model Availability Check:\n\n"

    switch model.availability {
    case .available:
      result += "✅ Default model is available and ready\n"
      result += "Supported languages: \(model.supportedLanguages.count)\n"
      result +=
        "Content tagging model: \(contentTaggingModel.availability == .available ? "✅" : "❌")\n"

    case .unavailable(let reason):
      result += "❌ Default model unavailable\n"
      switch reason {
      case .deviceNotEligible:
        result += "Reason: Device not eligible for Apple Intelligence\n"
      case .appleIntelligenceNotEnabled:
        result += "Reason: Apple Intelligence not enabled\n"
      case .modelNotReady:
        result += "Reason: Model assets not ready (downloading...)\n"
      @unknown default:
        result += "Reason: Unknown\n"
      }
    }

    self.response = result
    isLoading = false
  }

  @MainActor
  func executeToolCalling() async {
    isLoading = true
    response = ""
    errorMessage = ""

    do {
      // Create session with tools
      let session = LanguageModelSession(
        tools: [WeatherTool()],
        instructions: Instructions("You are a helpful assistant with access to weather tools.")
      )

      // Execute with tools
      let response = try await session.respond(
        to: Prompt("Is it hotter in New Delhi, or San Francisco?"))

      self.response = "Weather Comparison:\n\(response.content)\n\n"
    } catch {
      errorMessage = handleFoundationModelsError(error)
    }

    isLoading = false
  }

  @MainActor
  func executeCreativeWriting() async {
    isLoading = true
    response = ""
    errorMessage = ""

    do {
      // Create a basic session
      let session = LanguageModelSession()

      // Generate structured story outline
      let response = try await session.respond(
        to: Prompt("Create an outline for a mystery story set in a small town."),
        generating: StoryOutline.self
      )

      let storyOutline = response.content

      self.response = """
        Story Outline: \(storyOutline.title)

        Protagonist: \(storyOutline.protagonist)
        Setting: \(storyOutline.setting)
        Genre: \(storyOutline.genre)

        Central Conflict:
        \(storyOutline.conflict)
        """
    } catch {
      errorMessage = handleFoundationModelsError(error)
    }

    isLoading = false
  }

  @MainActor
  func executeBusinessIdea() async {
    isLoading = true
    response = ""
    errorMessage = ""

    do {
      // Create a basic session
      let session = LanguageModelSession()

      // Generate structured business idea
      let response = try await session.respond(
        to: Prompt("Generate a unique startup business idea for 2025."),
        generating: BusinessIdea.self
      )

      let businessIdea = response.content

      self.response = """
        Business: \(businessIdea.name)

        Description: \(businessIdea.description)

        Target Market: \(businessIdea.targetMarket)
        Revenue Model: \(businessIdea.revenueModel)

        Key Advantages:
        \(businessIdea.advantages.map { "• \($0)" }.joined(separator: "\n"))

        Estimated Startup Cost: \(businessIdea.estimatedStartupCost)
        """
    } catch {
      errorMessage = handleFoundationModelsError(error)
    }

    isLoading = false
  }

  // MARK: - Helper Methods

  @MainActor
  func clearResults() {
    response = ""
    errorMessage = ""
  }

  // MARK: - Error Handling

  private func handleFoundationModelsError(_ error: Error) -> String {
    if let generationError = error as? LanguageModelSession.GenerationError {
      return handleGenerationError(generationError)
    } else if let toolCallError = error as? LanguageModelSession.ToolCallError {
      return handleToolCallError(toolCallError)
    } else if let customError = error as? FoundationModelsError {
      return customError.localizedDescription
    } else {
      return "Unexpected error: \(error.localizedDescription)"
    }
  }

  private func handleGenerationError(_ error: LanguageModelSession.GenerationError) -> String {
    switch error {
    case .exceededContextWindowSize(let context):
      return "Context window exceeded: \(context.debugDescription)"
    case .assetsUnavailable(let context):
      return "Model assets unavailable: \(context.debugDescription)"
    case .guardrailViolation(let context):
      return "Content policy violation: \(context.debugDescription)"
    case .decodingFailure(let context):
      return "Failed to decode response: \(context.debugDescription)"
    case .unsupportedGuide(let context):
      return "Unsupported generation guide: \(context.debugDescription)"
    case .unsupportedLanguageOrLocale(let context):
      return "Unsupported language/locale: \(context.debugDescription)"
    @unknown default:
      return "Unknown generation error"
    }
  }

  private func handleToolCallError(_ error: LanguageModelSession.ToolCallError) -> String {
    return "Tool '\(error.tool.name)' failed: \(error.underlyingError.localizedDescription)"
  }
}
