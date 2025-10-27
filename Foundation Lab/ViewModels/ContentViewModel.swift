//
//  ContentViewModel.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/9/25.
//

import Foundation
import FoundationModels
import FoundationModelsTools
import Observation
import SwiftUI

/// ViewModel for managing ContentView state and operations
@MainActor
@Observable
class ContentViewModel {

  // MARK: - Published Properties

  var requestResponse: RequestResponsePair?
  var isLoading: Bool = false

  // MARK: - Computed Properties

  var hasContent: Bool {
    requestResponse != nil
  }

  // MARK: - Generic Execution Method

  @MainActor
  private func executeExample(_ requestText: String,
                             sessionBuilder: () -> LanguageModelSession = { LanguageModelSession(instructions: Instructions("You are a helpful assistant.")) },
                             sessionOperation: (LanguageModelSession) async throws -> String) async {
    setLoading(true)
    setRequestResponse(nil)

    do {
      let session = sessionBuilder()
      let response = try await sessionOperation(session)
      setRequestResponse(RequestResponsePair(request: requestText, response: response))
    } catch {
      setRequestResponse(RequestResponsePair(
        request: requestText,
        response: handleFoundationModelsError(error),
        isError: true
      ))
    }

    setLoading(false)
  }

  @MainActor
  private func executeExampleWithTools(_ requestText: String,
                                       tools: [any Tool],
                                      instructions: String = "You are a helpful assistant.",
                                      sessionOperation: (LanguageModelSession) async throws -> String) async {
    setLoading(true)
    setRequestResponse(nil)

    do {
      let session = LanguageModelSession(
        tools: tools,
        instructions: Instructions(instructions)
      )
      let response = try await sessionOperation(session)
      setRequestResponse(RequestResponsePair(request: requestText, response: response))
    } catch {
      setRequestResponse(RequestResponsePair(
        request: requestText,
        response: handleFoundationModelsError(error),
        isError: true
      ))
    }

    setLoading(false)
  }

  // MARK: - Example Operations

  @MainActor
  func executeBasicChat() async {
    let requestText = "Suggest a catchy name for a new coffee shop."

    await executeExample(requestText) { session in
      let response = try await session.respond(to: Prompt(requestText))
      return response.content
    }
  }

  @MainActor
  func executeStructuredData() async {
    let requestText = "Suggest a sci-fi book."

    await executeExample(requestText, sessionBuilder: { LanguageModelSession() }) { session in
      let response = try await session.respond(
        to: Prompt(requestText),
        generating: BookRecommendation.self
      )

      let bookInfo = response.content
      return """
        Title: \(bookInfo.title)
        Author: \(bookInfo.author)
        Genre: \(bookInfo.genre)
        Description: \(bookInfo.description)
        """
    }
  }

  @MainActor
  func executeGenerationGuides() async {
    let requestText = "Write a product review for a smartphone."

    await executeExample(requestText, sessionBuilder: { LanguageModelSession() }) { session in
      let response = try await session.respond(
        to: Prompt(requestText),
        generating: ProductReview.self
      )

      let review = response.content
      return """
        Product: \(review.productName)
        Rating: \(review.rating)/5
        Review: \(review.reviewText)
        Recommendation: \(review.recommendation)

        Pros: \(review.pros.joined(separator: ", "))
        Cons: \(review.cons.joined(separator: ", "))
        """
    }
  }

  @MainActor
  func executeWeatherToolCalling() async {
    let requestText = "Is it hotter in New Delhi, or San Francisco? Compare the weather in both cities."

    await executeExampleWithTools(requestText,
                                 tools: [WeatherTool()],
                                 instructions: "You are a helpful assistant with access to weather tools.") { session in
      let response = try await session.respond(to: Prompt(requestText))
      return "Weather Comparison:\n\(response.content)\n\n"
    }
  }

  @MainActor
  func executeWebSearchToolCalling() async {
    let requestText = "Search about WWDC 2025 announcements, especially the Foundation Model framework"

    await executeExampleWithTools(requestText,
                                 tools: [WebTool()],
                                 instructions: "You are a helpful assistant with access to web search tools. Summarize the result.") { session in
      let response = try await session.respond(to: Prompt(requestText))
      return "Web Search Results:\n\(response.content)\n\n"
    }
  }

  @MainActor
  func executeCreativeWriting() async {
    let requestText = "Create an outline for a mystery story set in a small town."

    await executeExample(requestText, sessionBuilder: { LanguageModelSession() }) { session in
      let response = try await session.respond(
        to: Prompt(requestText),
        generating: StoryOutline.self
      )

      let storyOutline = response.content
      return """
        Story Outline: \(storyOutline.title)

        Protagonist: \(storyOutline.protagonist)
        Setting: \(storyOutline.setting)
        Genre: \(storyOutline.genre)

        Central Conflict:
        \(storyOutline.conflict)
        """
    }
  }

  @MainActor
  func executeBusinessIdea() async {
    let requestText = "Generate a unique startup business idea for 2025."

    await executeExample(requestText, sessionBuilder: { LanguageModelSession() }) { session in
      let response = try await session.respond(
        to: Prompt(requestText),
        generating: BusinessIdea.self
      )

      let businessIdea = response.content
      return """
        Business: \(businessIdea.name)

        Description: \(businessIdea.description)

        Target Market: \(businessIdea.targetMarket)
        Revenue Model: \(businessIdea.revenueModel)

        Key Advantages:
        \(businessIdea.advantages.map { "• \($0)" }.joined(separator: "\n"))

        Estimated Startup Cost: \(businessIdea.estimatedStartupCost)
        """
    }
  }

  // MARK: - Helper Methods

  @MainActor
  func clearResults() {
    requestResponse = nil
  }

  private func setLoading(_ loading: Bool) {
    isLoading = loading
  }

  private func setRequestResponse(_ response: RequestResponsePair?) {
    requestResponse = response
  }

}

// MARK: - Error Handling

extension ContentViewModel {
  func handleFoundationModelsError(_ error: Error) -> String {
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
    case .rateLimited(let context):
      return "Rate limited: \(context.debugDescription)"
    case .concurrentRequests(let context):
        return "Concurrent requests limit exceeded: \(context.debugDescription)"
        // Refusal is async throws
    case .refusal(_, let context):
        return "Model refused to respond: \(context.debugDescription)"
    @unknown default:
      return "Unknown generation error"
    }
  }

  private func handleToolCallError(_ error: LanguageModelSession.ToolCallError) -> String {
    return "Tool '\(error.tool.name)' failed: \(error.underlyingError.localizedDescription)"
  }
}

// MARK: - Special Execute Methods

extension ContentViewModel {
  @MainActor
  func executeStreaming() async {
    let requestText = "Write a haiku about destiny."
    setLoading(true)
    setRequestResponse(nil)

    do {
      // Create a basic session
      let session = LanguageModelSession()

      // Create streaming response
      let stream = session.streamResponse(to: Prompt(requestText))

      // Set initial request with empty response
      setRequestResponse(RequestResponsePair(request: requestText, response: ""))

      var finalContent = ""

      // Process streaming updates
      for try await partialResponse in stream {
          finalContent = partialResponse.content
          setRequestResponse(RequestResponsePair(request: requestText, response: partialResponse.content))
      }

      // Use the last received content as final response
      setRequestResponse(RequestResponsePair(request: requestText, response: finalContent))
      setLoading(false)
    } catch {
      setRequestResponse(RequestResponsePair(
          request: requestText,
          response: handleFoundationModelsError(error),
          isError: true
      ))
      setLoading(false)
    }
  }

  @MainActor
  func executeModelAvailability() async {
    let requestText = "Check system model availability and capabilities"
    setLoading(true)
    setRequestResponse(nil)

    // Check model availability
    let model = SystemLanguageModel.default
    let contentTaggingModel = SystemLanguageModel(useCase: .contentTagging)

    var result = "Model Availability Check:\n\n"

    switch model.availability {
    case .available:
      result += "Default model is available and ready\n"
      result += "Supported languages: \(model.supportedLanguages.count)\n"
      let status = contentTaggingModel.availability == .available ? "Available" : "Unavailable"
      result += "Content tagging model: \(status)\n"

    case .unavailable(let reason):
      result += "Default model unavailable\n"
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

    setRequestResponse(RequestResponsePair(request: requestText, response: result))
    setLoading(false)
  }
}
