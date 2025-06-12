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
        instructions: "You are a helpful assistant."
      )
    }
  }

  @MainActor
  func executeStructuredData() async {
    await executeExample {
      let bookInfo = try await self.foundationModelsService.generateStructuredData(
        prompt: "Suggest a sci-fi book.",
        type: BookRecommendation.self
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
        type: ProductReview.self
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
    await executeExample {
      let weatherResult = try await self.foundationModelsService.executeWithTools(
        prompt: "Is it hotter in New Delhi, or San Francisco?"
      )

      var result = "Weather Comparison:\n\(weatherResult.response)\n\n"

      return result
    }
  }

  @MainActor
  func executeCreativeWriting() async {
    await executeExample {
      let storyOutline = try await self.foundationModelsService.generateStructuredData(
        prompt: "Create an outline for a mystery story set in a small town.",
        type: StoryOutline.self
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
    await executeExample {
      let businessIdea = try await self.foundationModelsService.generateStructuredData(
        prompt: "Generate a unique startup business idea for 2025.",
        type: BusinessIdea.self
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
  private func executeExample(_ operation: @escaping () async throws -> String) async {
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
}
