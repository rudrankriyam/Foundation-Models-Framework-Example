//
//  ToolExecutor.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import Foundation
import FoundationModels

/// A reusable helper class that eliminates code duplication across tool views
/// by providing a standardized pattern for executing tool operations
@MainActor
@Observable
final class ToolExecutor {
  var isRunning = false
  var result: String = ""
  var errorMessage: String?
  var successMessage: String?

  /// Executes a tool operation with standardized state management
  func execute<T: Tool>(
    tool: T,
    prompt: String,
    successMessage: String? = nil,
    clearForm: (() -> Void)? = nil
  ) async {
    await performExecution(successMessage: successMessage, clearForm: clearForm) {
      let session = LanguageModelSession(tools: [tool])
      let response = try await session.respond(to: Prompt(prompt))
      return response.content
    }
  }

  /// Executes a tool operation using PromptBuilder
  func executeWithPromptBuilder<T: Tool>(
    tool: T,
    successMessage: String? = nil,
    clearForm: (() -> Void)? = nil,
    @PromptBuilder promptBuilder: () -> Prompt
  ) async {
    await performExecution(successMessage: successMessage, clearForm: clearForm) {
      let session = LanguageModelSession(tools: [tool])
      let response = try await session.respond(to: promptBuilder())
      return response.content
    }
  }

  /// Executes a tool operation with a custom session configuration
  func executeWithCustomSession(
    sessionBuilder: () -> LanguageModelSession,
    prompt: String,
    successMessage: String? = nil,
    clearForm: (() -> Void)? = nil
  ) async {
    await performExecution(successMessage: successMessage, clearForm: clearForm) {
      let session = sessionBuilder()
      let response = try await session.respond(to: Prompt(prompt))
      return response.content
    }
  }

  /// Private helper that encapsulates common state management logic
  private func performExecution(
    successMessage: String? = nil,
    clearForm: (() -> Void)? = nil,
    operation: () async throws -> String
  ) async {
    isRunning = true
    errorMessage = nil
    self.successMessage = nil
    result = ""

    do {
      result = try await operation()

      if let successMessage = successMessage {
        self.successMessage = successMessage
      }

      clearForm?()

    } catch {
      errorMessage = FoundationModelsErrorHandler.handleError(error)
      self.successMessage = nil
    }

    isRunning = false
  }

  /// Clears all state
  func clear() {
    isRunning = false
    result = ""
    errorMessage = nil
    successMessage = nil
  }
}
