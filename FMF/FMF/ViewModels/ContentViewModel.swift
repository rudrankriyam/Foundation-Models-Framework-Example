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

  var requestResponse: RequestResponsePair?
  var isLoading: Bool = false

  // MARK: - Computed Properties

  var hasContent: Bool {
    requestResponse != nil
  }

  // MARK: - Example Operations

  @MainActor
  func executeBasicChat() async {
    let requestText = "Suggest a catchy name for a new coffee shop."
    isLoading = true
    requestResponse = nil

    do {
      // Create a basic session
      let session = LanguageModelSession(instructions: Instructions("You are a helpful assistant."))

      // Generate response
      let response = try await session.respond(
        to: Prompt(requestText))

      self.requestResponse = RequestResponsePair(
        request: requestText,
        response: response.content
      )
    } catch {
      self.requestResponse = RequestResponsePair(
        request: requestText,
        response: handleFoundationModelsError(error),
        isError: true
      )
    }

    isLoading = false
  }

  @MainActor
  func executeStructuredData() async {
    let requestText = "Suggest a sci-fi book."
    isLoading = true
    requestResponse = nil

    do {
      // Create a basic session
      let session = LanguageModelSession()

      // Generate structured data
      let response = try await session.respond(
        to: Prompt(requestText),
        generating: BookRecommendation.self
      )

      let bookInfo = response.content

      let responseText = """
        Title: \(bookInfo.title)
        Author: \(bookInfo.author)
        Genre: \(bookInfo.genre)
        Description: \(bookInfo.description)
        """
      
      self.requestResponse = RequestResponsePair(
        request: requestText,
        response: responseText
      )
    } catch {
      self.requestResponse = RequestResponsePair(
        request: requestText,
        response: handleFoundationModelsError(error),
        isError: true
      )
    }

    isLoading = false
  }

  @MainActor
  func executeGenerationGuides() async {
    let requestText = "Write a product review for a smartphone."
    isLoading = true
    requestResponse = nil

    do {
      // Create a basic session
      let session = LanguageModelSession()

      // Generate structured product review
      let response = try await session.respond(
        to: Prompt(requestText),
        generating: ProductReview.self
      )

      let review = response.content

      let responseText = """
        Product: \(review.productName)
        Rating: \(review.rating)/5
        Review: \(review.reviewText)
        Recommendation: \(review.recommendation)

        Pros: \(review.pros.joined(separator: ", "))
        Cons: \(review.cons.joined(separator: ", "))
        """
      
      self.requestResponse = RequestResponsePair(
        request: requestText,
        response: responseText
      )
    } catch {
      self.requestResponse = RequestResponsePair(
        request: requestText,
        response: handleFoundationModelsError(error),
        isError: true
      )
    }

    isLoading = false
  }

  @MainActor
  func executeStreaming() async {
    let requestText = "Write a short poem about technology."
    isLoading = true
    requestResponse = nil

    do {
      // Create a basic session
      let session = LanguageModelSession()

      // Create streaming response
      let stream = session.streamResponse(to: Prompt(requestText))

      // Set initial request with empty response
      self.requestResponse = RequestResponsePair(
        request: requestText,
        response: ""
      )

      // Process streaming updates
      for try await partialResponse in stream {
        self.requestResponse = RequestResponsePair(
          request: requestText,
          response: partialResponse
        )
      }

      // Get final response
      let finalResponse = try await stream.collect()
      self.requestResponse = RequestResponsePair(
        request: requestText,
        response: finalResponse.content
      )
      isLoading = false
    } catch {
      self.requestResponse = RequestResponsePair(
        request: requestText,
        response: handleFoundationModelsError(error),
        isError: true
      )
      isLoading = false
    }
  }

  @MainActor
  func executeModelAvailability() async {
    let requestText = "Check system model availability and capabilities"
    isLoading = true
    requestResponse = nil

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

    self.requestResponse = RequestResponsePair(
      request: requestText,
      response: result
    )
    isLoading = false
  }

  @MainActor
  func executeWeatherToolCalling() async {
    let requestText = "Is it hotter in New Delhi, or San Francisco? Compare the weather in both cities."
    isLoading = true
    requestResponse = nil

    do {
      // Create session with weather tool
      let session = LanguageModelSession(
        tools: [WeatherTool()],
        instructions: Instructions("You are a helpful assistant with access to weather tools.")
      )

      // Execute with weather tool
      let response = try await session.respond(
        to: Prompt(requestText))

      self.requestResponse = RequestResponsePair(
        request: requestText,
        response: "Weather Comparison:\n\(response.content)\n\n"
      )
    } catch {
      self.requestResponse = RequestResponsePair(
        request: requestText,
        response: handleFoundationModelsError(error),
        isError: true
      )
    }

    isLoading = false
  }

  @MainActor
  func executeWebSearchToolCalling() async {
    let requestText = "Search about WWDC 2025 announcements, especially the Foundation Model framework"
    isLoading = true
    requestResponse = nil

    do {
      // Create session with web search tool
      let session = LanguageModelSession(
        tools: [WebTool()],
        instructions: Instructions("You are a helpful assistant with access to web search tools. Summarize the result.")
      )

      // Execute with web search tool
      let response = try await session.respond(
        to: requestText)

      self.requestResponse = RequestResponsePair(
        request: requestText,
        response: "Web Search Results:\n\(response.content)\n\n"
      )
    } catch {
      self.requestResponse = RequestResponsePair(
        request: requestText,
        response: handleFoundationModelsError(error),
        isError: true
      )
    }

    isLoading = false
  }

  @MainActor
  func executeCreativeWriting() async {
    let requestText = "Create an outline for a mystery story set in a small town."
    isLoading = true
    requestResponse = nil

    do {
      // Create a basic session
      let session = LanguageModelSession()

      // Generate structured story outline
      let response = try await session.respond(
        to: Prompt(requestText),
        generating: StoryOutline.self
      )

      let storyOutline = response.content

      let responseText = """
        Story Outline: \(storyOutline.title)

        Protagonist: \(storyOutline.protagonist)
        Setting: \(storyOutline.setting)
        Genre: \(storyOutline.genre)

        Central Conflict:
        \(storyOutline.conflict)
        """
      
      self.requestResponse = RequestResponsePair(
        request: requestText,
        response: responseText
      )
    } catch {
      self.requestResponse = RequestResponsePair(
        request: requestText,
        response: handleFoundationModelsError(error),
        isError: true
      )
    }

    isLoading = false
  }

  @MainActor
  func executeBusinessIdea() async {
    let requestText = "Generate a unique startup business idea for 2025."
    isLoading = true
    requestResponse = nil

    do {
      // Create a basic session
      let session = LanguageModelSession()

      // Generate structured business idea
      let response = try await session.respond(
        to: Prompt(requestText),
        generating: BusinessIdea.self
      )

      let businessIdea = response.content

      let responseText = """
        Business: \(businessIdea.name)

        Description: \(businessIdea.description)

        Target Market: \(businessIdea.targetMarket)
        Revenue Model: \(businessIdea.revenueModel)

        Key Advantages:
        \(businessIdea.advantages.map { "• \($0)" }.joined(separator: "\n"))

        Estimated Startup Cost: \(businessIdea.estimatedStartupCost)
        """
      
      self.requestResponse = RequestResponsePair(
        request: requestText,
        response: responseText
      )
    } catch {
      self.requestResponse = RequestResponsePair(
        request: requestText,
        response: handleFoundationModelsError(error),
        isError: true
      )
    }

    isLoading = false
  }

  // MARK: - Helper Methods

  @MainActor
  func clearResults() {
    requestResponse = nil
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
