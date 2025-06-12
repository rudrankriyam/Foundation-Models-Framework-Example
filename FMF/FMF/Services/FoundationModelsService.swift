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
    let defaultInstructions = "You are a helpful assistant with access to weather tools."
    let finalInstructions = instructions ?? defaultInstructions

    let session = LanguageModelSession(
      tools: [weatherTool],
      instructions: Instructions(finalInstructions)
    )
    currentSession = session
    return session
  }

  // MARK: - Basic Operations

  func generateResponse(
    prompt: String, instructions: String? = nil
  ) async throws -> String {
    let session = createBasicSession(instructions: instructions)
    let response = try await session.respond(to: Prompt(prompt))
    return response.content
  }

  func generateStructuredData<T: Generable>(
    prompt: String,
    type: T.Type,
    instructions: String? = nil
  ) async throws -> T {
    let session = createBasicSession(instructions: instructions)
    let response = try await session.respond(to: Prompt(prompt), generating: type)
    return response.content
  }

  // MARK: - Streaming Operations

  func streamResponse(
    prompt: String,
    instructions: String? = nil,
    onPartialUpdate: @escaping (String) -> Void
  ) async throws -> String {
    let session = createBasicSession(instructions: instructions)
    let stream = session.streamResponse(to: Prompt(prompt))

    for try await partialResponse in stream {
      onPartialUpdate(partialResponse)
    }

    let finalResponse = try await stream.collect()
    return finalResponse.content
  }

  // MARK: - Tool Operations

  func executeWithTools(prompt: String) async throws -> (response: String, transcriptCount: Int) {
    let session = createSessionWithTools()
    let response = try await session.respond(to: Prompt(prompt))
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
