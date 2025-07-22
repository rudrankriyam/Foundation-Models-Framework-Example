//
//  FoundationModelsError.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/9/25.
//

import Foundation
import FoundationModels

/// Custom error types for Foundation Models operations
nonisolated enum FoundationModelsError: LocalizedError, Sendable {
  case sessionCreationFailed
  case responseGenerationFailed(String)
  case toolCallFailed(String)
  case streamingFailed(String)
  case modelUnavailable(String)

  var errorDescription: String? {
    switch self {
    case .sessionCreationFailed:
      return "Failed to create language model session"
    case .responseGenerationFailed(let message):
      return "Response generation failed: \(message)"
    case .toolCallFailed(let message):
      return "Tool call failed: \(message)"
    case .streamingFailed(let message):
      return "Streaming failed: \(message)"
    case .modelUnavailable(let message):
      return "Model unavailable: \(message)"
    }
  }
}

/// Helper for handling LanguageModelSession errors
struct FoundationModelsErrorHandler: Sendable {
  static func handleGenerationError(_ error: LanguageModelSession.GenerationError) -> String {
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
      return "Too many concurrent requests: \(context.debugDescription)"
    @unknown default:
      return "Unknown generation error"
    }
  }

  static func handleToolCallError(_ error: LanguageModelSession.ToolCallError) -> String {
    return "Tool '\(error.tool.name)' failed: \(error.underlyingError.localizedDescription)"
  }
}
