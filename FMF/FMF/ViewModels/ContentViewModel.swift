//
//  ContentViewModel.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/9/25.
//

import Foundation
import FoundationModels
import Observation
import SwiftUI

/// ViewModel for managing ContentView state and operations
@Observable
final class ContentViewModel {

  // MARK: - Published Properties

  var response: String = ""
  var isLoading: Bool = false
  var errorMessage: String = ""
  var performanceMetrics = PerformanceMetrics()

  // MARK: - Dependencies

  private let foundationModelsService = FoundationModelsService()

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
    await executeExample {
      try await self.foundationModelsService.generateResponse(
        prompt: "Suggest a catchy name for a new coffee shop.",
        instructions: "You are a helpful assistant.",
        performanceMetrics: self.performanceMetrics
      )
    }
  }

  @MainActor
  func executeStructuredData() async {
    await executeExample {
      let bookInfo = try await self.foundationModelsService.generateStructuredData(
        prompt: "Suggest a sci-fi book.",
        type: BookRecommendation.self,
        performanceMetrics: self.performanceMetrics
      )

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
    await executeExample {
      let review = try await self.foundationModelsService.generateStructuredData(
        prompt: "Write a product review for a smartphone.",
        type: ProductReview.self,
        performanceMetrics: self.performanceMetrics
      )

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
  func executeStreaming() async {
    isLoading = true
    response = ""
    errorMessage = ""

    do {
      let finalResponse = try await foundationModelsService.streamResponse(
        prompt: "Write a short poem about technology.",
        performanceMetrics: performanceMetrics,
        onPartialUpdate: { [weak self] partialText in
          Task { @MainActor in
            self?.response = partialText
          }
        }
      )

      response = finalResponse
      isLoading = false
    } catch {
      errorMessage = foundationModelsService.handleError(error)
      isLoading = false
    }
  }

  @MainActor
  func executeModelAvailability() async {
    await executeExample {
      let availabilityInfo = self.foundationModelsService.checkModelAvailability()
      return availabilityInfo.availabilityDescription
    }
  }

  @MainActor
  func executeToolCalling() async {
    await executeExample(operationType: .toolCalling) {
      let weatherResult = try await self.foundationModelsService.executeWithTools(
        prompt: "Is it hotter in New Delhi, or San Francisco?",
        performanceMetrics: self.performanceMetrics
      )

      var result = "Weather Comparison:\n\(weatherResult.response)\n\n"

      let recipeResult = try await self.foundationModelsService.executeWithTools(
        prompt: "Find three sourdough bread recipes"
      )

      result += "Recipe Search:\n\(recipeResult.response)\n\n"
      result += "Total transcript entries: \(recipeResult.transcriptCount)"

      return result
    }
  }

  @MainActor
  func executeCreativeWriting() async {
    await executeExample(operationType: .creative) {
      let storyOutline = try await self.foundationModelsService.generateStructuredData(
        prompt: "Create an outline for a mystery story set in a small town.",
        type: StoryOutline.self,
        performanceMetrics: self.performanceMetrics
      )

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
    await executeExample(operationType: .business) {
      let businessIdea = try await self.foundationModelsService.generateStructuredData(
        prompt: "Generate a unique startup business idea for 2025.",
        type: BusinessIdea.self,
        performanceMetrics: self.performanceMetrics
      )

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
  private func executeExample(
    operationType: OperationType? = nil, _ operation: @escaping () async throws -> String
  ) async {
    isLoading = true
    response = ""
    errorMessage = ""

    do {
      let result = try await operation()
      response = result
    } catch {
      errorMessage = foundationModelsService.handleError(error)
    }

    isLoading = false
  }

  @MainActor
  func clearResults() {
    response = ""
    errorMessage = ""
  }

  @MainActor
  func resetPerformanceMetrics() {
    performanceMetrics.reset()
  }
}
