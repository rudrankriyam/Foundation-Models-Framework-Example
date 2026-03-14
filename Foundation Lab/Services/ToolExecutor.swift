//
//  ToolExecutor.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import Foundation
import FoundationLabCore

/// A reusable helper class that eliminates code duplication across tool views
/// by providing a standardized pattern for executing tool operations
@MainActor
@Observable
final class ToolExecutor {
  var isRunning = false
  var result: String = ""
  var errorMessage: String?
  var successMessage: String?

  /// Executes a shared FoundationLabCore capability that returns generated text.
  func executeCapability(
    successMessage: String? = nil,
    clearForm: (@MainActor () -> Void)? = nil,
    operation: () async throws -> TextGenerationResult
  ) async {
    await performExecution(successMessage: successMessage, clearForm: clearForm) {
      let response = try await operation()
      return response.content
    }
  }

  /// Private helper that encapsulates common state management logic
  private func performExecution(
    successMessage: String? = nil,
    clearForm: (@MainActor () -> Void)? = nil,
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
