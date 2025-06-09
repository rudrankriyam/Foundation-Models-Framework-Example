//
//  FoundationModelsService.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/9/25.
//

import Foundation
import FoundationModels
import Observation

/// Service class for managing Foundation Models operations
@Observable
final class FoundationModelsService {

  // MARK: - Properties

  private var currentSession: LanguageModelSession?
  private let weatherTool = WeatherTool()
  private let breadTool = BreadDatabaseTool()

  // MARK: - Session Management

  func createBasicSession(instructions: String? = nil) -> LanguageModelSession {
    let session: LanguageModelSession
    if let instructions = instructions {
      session = LanguageModelSession(instructions: Instructions(instructions))
    } else {
      session = LanguageModelSession()
    }
    currentSession = session
    return session
  }

  func createSessionWithTools(instructions: String? = nil) -> LanguageModelSession {
    let defaultInstructions = "You are a helpful assistant with access to weather and recipe tools."
    let finalInstructions = instructions ?? defaultInstructions

    let session = LanguageModelSession(
      tools: [weatherTool, breadTool],
      instructions: Instructions(finalInstructions)
    )
    currentSession = session
    return session
  }

  // MARK: - Basic Operations

  func generateResponse(
    prompt: String, instructions: String? = nil, performanceMetrics: PerformanceMetrics? = nil
  ) async throws -> String {
    performanceMetrics?.startTracking(operationType: .basic, promptLength: prompt.count)

    let session = createBasicSession(instructions: instructions)
    let response = try await session.respond(to: Prompt(prompt))

    // Estimate token count based on response length (rough approximation)
    let estimatedTokens = estimateTokenCount(from: response.content)
    performanceMetrics?.finishTracking(totalTokens: estimatedTokens)

    return response.content
  }

  func generateStructuredData<T: Generable>(
    prompt: String,
    type: T.Type,
    instructions: String? = nil,
    performanceMetrics: PerformanceMetrics? = nil
  ) async throws -> T {
    performanceMetrics?.startTracking(operationType: .structured, promptLength: prompt.count)

    let session = createBasicSession(instructions: instructions)
    let response = try await session.respond(to: Prompt(prompt), generating: type)

    // Estimate token count for structured response
    let responseString = String(describing: response.content)
    let estimatedTokens = estimateTokenCount(from: responseString)
    performanceMetrics?.finishTracking(totalTokens: estimatedTokens)

    return response.content
  }

  // MARK: - Streaming Operations

  func streamResponse(
    prompt: String,
    instructions: String? = nil,
    performanceMetrics: PerformanceMetrics? = nil,
    onPartialUpdate: @escaping (String) -> Void
  ) async throws -> String {
    performanceMetrics?.startTracking(operationType: .streaming, promptLength: prompt.count)

    let session = createBasicSession(instructions: instructions)
    let stream = session.streamResponse(to: Prompt(prompt))

    for try await partialResponse in stream {
      performanceMetrics?.addStreamingToken(at: Date())
      onPartialUpdate(partialResponse)
    }

    let finalResponse = try await stream.collect()
    let estimatedTokens = estimateTokenCount(from: finalResponse.content)
    performanceMetrics?.finishTracking(totalTokens: estimatedTokens)

    return finalResponse.content
  }

  // MARK: - Tool Operations

  func executeWithTools(prompt: String, performanceMetrics: PerformanceMetrics? = nil) async throws
    -> (response: String, transcriptCount: Int)
  {
    performanceMetrics?.startTracking(operationType: .toolCalling, promptLength: prompt.count)

    let session = createSessionWithTools()
    let response = try await session.respond(to: Prompt(prompt))

    let estimatedTokens = estimateTokenCount(from: response.content)
    performanceMetrics?.finishTracking(totalTokens: estimatedTokens)

    return (response.content, session.transcript.entries.count)
  }

  // MARK: - Model Availability

  func checkModelAvailability() -> ModelAvailabilityInfo {
    let model = SystemLanguageModel.default
    let contentTaggingModel = SystemLanguageModel(useCase: .contentTagging)

    return ModelAvailabilityInfo(
      defaultModel: model,
      contentTaggingModel: contentTaggingModel
    )
  }

  // MARK: - Error Handling

  func handleError(_ error: Error) -> String {
    if let generationError = error as? LanguageModelSession.GenerationError {
      return FoundationModelsErrorHandler.handleGenerationError(generationError)
    } else if let toolCallError = error as? LanguageModelSession.ToolCallError {
      return FoundationModelsErrorHandler.handleToolCallError(toolCallError)
    } else if let customError = error as? FoundationModelsError {
      return customError.localizedDescription
    } else {
      return "Unexpected error: \(error.localizedDescription)"
    }
  }

  // MARK: - Helper Methods

  /// Estimates token count using industry-standard approximations
  /// Based on OpenAI's guidelines: 1 token ≈ 4 chars OR 1 token ≈ 0.75 words
  /// Uses the maximum of both calculations for conservative estimation
  private func estimateTokenCount(from text: String) -> Int {
    // Method 1: Character-based (1 token ≈ 4 characters)
    let charBasedTokens = Double(text.count) / 4.0

    // Method 2: Word-based (1 token ≈ 0.75 words, so tokens = words / 0.75)
    let wordCount = text.split(separator: " ").count
    let wordBasedTokens = Double(wordCount) / 0.75

    // Use the maximum for conservative estimation (as recommended by OpenAI)
    let estimatedTokens = max(charBasedTokens, wordBasedTokens)

    return Int(ceil(estimatedTokens))
  }
}

// MARK: - Supporting Types

struct ModelAvailabilityInfo {
  let defaultModel: SystemLanguageModel
  let contentTaggingModel: SystemLanguageModel

  var isDefaultModelAvailable: Bool {
    defaultModel.availability == .available
  }

  var isContentTaggingAvailable: Bool {
    contentTaggingModel.availability == .available
  }

  var availabilityDescription: String {
    var result = "Model Availability Check:\n\n"

    switch defaultModel.availability {
    case .available:
      result += "✅ Default model is available and ready\n"
      result += "Supported languages: \(defaultModel.supportedLanguages.count)\n"
      result += "Content tagging model: \(isContentTaggingAvailable ? "✅" : "❌")\n"

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

    return result
  }
}
