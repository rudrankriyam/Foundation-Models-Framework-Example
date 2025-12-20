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
  /// - Parameters:
  ///   - operation: The async operation to execute
  ///   - successMessage: Optional success message to display
  ///   - clearForm: Optional closure to clear form data on success
  func execute<T: Tool>(
    tool: T,
    prompt: String,
    successMessage: String? = nil,
    clearForm: (() -> Void)? = nil
  ) async {
    isRunning = true
    errorMessage = nil
    self.successMessage = nil
    result = ""

    do {
      let session = LanguageModelSession(tools: [tool])
      let response = try await session.respond(to: Prompt(prompt))
      result = response.content

      if let successMessage = successMessage {
        self.successMessage = successMessage
      }

      clearForm?()

    } catch {
      errorMessage = FoundationModelsErrorHandler.handleError(error)
      // Clear success message on error
      self.successMessage = nil
    }

    isRunning = false
  }

  /// Executes a tool operation using PromptBuilder
  /// - Parameters:
  ///   - tool: The tool to execute
  ///   - successMessage: Optional success message to display
  ///   - clearForm: Optional closure to clear form data on success
  ///   - promptBuilder: A closure that builds the prompt using @PromptBuilder
  func executeWithPromptBuilder<T: Tool>(
    tool: T,
    successMessage: String? = nil,
    clearForm: (() -> Void)? = nil,
    @PromptBuilder promptBuilder: () -> Prompt
  ) async {
    isRunning = true
    errorMessage = nil
    self.successMessage = nil
    result = ""

    do {
      let session = LanguageModelSession(tools: [tool])
      let response = try await session.respond(to: promptBuilder())
      result = response.content

      if let successMessage = successMessage {
        self.successMessage = successMessage
      }

      clearForm?()

    } catch {
      errorMessage = FoundationModelsErrorHandler.handleError(error)
      // Clear success message on error
      self.successMessage = nil
    }

    isRunning = false
  }

  /// Executes a tool operation with a custom session configuration
  /// - Parameters:
  ///   - sessionBuilder: Custom session builder closure
  ///   - successMessage: Optional success message to display
  ///   - clearForm: Optional closure to clear form data on success
  func executeWithCustomSession(
    sessionBuilder: () -> LanguageModelSession,
    prompt: String,
    successMessage: String? = nil,
    clearForm: (() -> Void)? = nil
  ) async {
    isRunning = true
    errorMessage = nil
    self.successMessage = nil
    result = ""

    do {
      let session = sessionBuilder()
      let response = try await session.respond(to: Prompt(prompt))
      result = response.content

      if let successMessage = successMessage {
        self.successMessage = successMessage
      }

      clearForm?()

    } catch {
      errorMessage = FoundationModelsErrorHandler.handleError(error)
      // Clear success message on error
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
