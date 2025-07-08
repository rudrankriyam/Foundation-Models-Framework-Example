//
//  ExampleExecutor.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import Foundation
import FoundationModels
import SwiftUI

/// A reusable helper class for executing example operations
@MainActor
@Observable
final class ExampleExecutor {
  var isRunning = false
  var result: String = ""
  var errorMessage: String?
  var successMessage: String?
  var promptHistory: [String] = []
  
  /// Executes a basic language model operation
  func executeBasic(
    prompt: String,
    instructions: String? = nil,
    successMessage: String? = nil
  ) async {
    guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      errorMessage = "Please enter a valid prompt"
      return
    }
    
    isRunning = true
    errorMessage = nil
    self.successMessage = nil
    result = ""
    
    // Add to history
    addToHistory(prompt)
    
    do {
      let session: LanguageModelSession
      if let instructions = instructions {
        session = LanguageModelSession(instructions: Instructions(instructions))
      } else {
        session = LanguageModelSession()
      }
      
      let response = try await session.respond(to: Prompt(prompt))
      result = response.content
      
      if let successMessage = successMessage {
        self.successMessage = successMessage
      }
      
    } catch {
      errorMessage = handleError(error)
      self.successMessage = nil
    }
    
    isRunning = false
  }
  
  /// Executes a structured data generation operation
  func executeStructured<T: Generable>(
    prompt: String,
    type: T.Type,
    formatter: @escaping (T) -> String
  ) async {
    guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      errorMessage = "Please enter a valid prompt"
      return
    }
    
    isRunning = true
    errorMessage = nil
    successMessage = nil
    result = ""
    
    // Add to history
    addToHistory(prompt)
    
    do {
      let session = LanguageModelSession()
      let response = try await session.respond(
        to: Prompt(prompt),
        generating: type
      )
      
      result = formatter(response.content)
      
    } catch {
      errorMessage = handleError(error)
    }
    
    isRunning = false
  }
  
  /// Executes a streaming operation
  func executeStreaming(
    prompt: String,
    instructions: String? = nil,
    onPartialResult: @escaping (String) -> Void
  ) async {
    guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      errorMessage = "Please enter a valid prompt"
      return
    }
    
    isRunning = true
    errorMessage = nil
    successMessage = nil
    result = ""
    
    // Add to history
    addToHistory(prompt)
    
    do {
      let session: LanguageModelSession
      if let instructions = instructions {
        session = LanguageModelSession(instructions: Instructions(instructions))
      } else {
        session = LanguageModelSession()
      }
      
      let stream = session.streamResponse(to: Prompt(prompt))
      
      for try await partialResponse in stream {
        result = partialResponse
        onPartialResult(partialResponse)
      }
      
    } catch {
      errorMessage = handleError(error)
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
  
  /// Adds a prompt to history
  private func addToHistory(_ prompt: String) {
    // Remove if already exists
    promptHistory.removeAll { $0 == prompt }
    // Add to beginning
    promptHistory.insert(prompt, at: 0)
    // Keep only last 10
    if promptHistory.count > 10 {
      promptHistory = Array(promptHistory.prefix(10))
    }
  }
  
  /// Handles various error types and returns user-friendly messages
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

// MARK: - Environment Key

private struct ExampleExecutorKey: EnvironmentKey {
  static let defaultValue = ExampleExecutor()
}

extension EnvironmentValues {
  var exampleExecutor: ExampleExecutor {
    get { self[ExampleExecutorKey.self] }
    set { self[ExampleExecutorKey.self] = newValue }
  }
}

// MARK: - View Modifier

struct ExampleExecutorModifier: ViewModifier {
  @State private var executor = ExampleExecutor()
  
  func body(content: Content) -> some View {
    content
      .environment(\.exampleExecutor, executor)
  }
}

extension View {
  /// Provides an ExampleExecutor instance to the view hierarchy
  func withExampleExecutor() -> some View {
    modifier(ExampleExecutorModifier())
  }
}