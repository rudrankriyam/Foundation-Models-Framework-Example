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
@Observable
final class ExampleExecutor {
    var isRunning = false
    var result: String = ""
    var errorMessage: String?
    var successMessage: String?
    var promptHistory: [String] = []

    /// Token count from the last operation. Updated after each execution.
    private(set) var lastTokenCount: Int?

    /// Executes a basic language model operation
    func executeBasic(
        prompt: String,
        instructions: String? = nil,
        successMessage: String? = nil,
        guardrails: SystemLanguageModel.Guardrails = .default
    ) async {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a valid prompt"
            return
        }

        isRunning = true
        errorMessage = nil
        self.successMessage = nil
        result = ""
        lastTokenCount = nil

        addToHistory(prompt)

        do {
            let session: LanguageModelSession
            let model = SystemLanguageModel(useCase: .general, guardrails: guardrails)

            if let instructions = instructions {
                session = LanguageModelSession(model: model, instructions: Instructions(instructions))
            } else {
                session = LanguageModelSession(model: model)
            }

            let response = try await session.respond(to: Prompt(prompt))
            result = response.content

            lastTokenCount = await session.transcript.tokenCount(using: model)

            if let successMessage = successMessage {
                self.successMessage = successMessage
            }

        } catch {
            errorMessage = FoundationModelsErrorHandler.handleError(error)
            self.successMessage = nil
        }

        isRunning = false
    }

    /// Executes a structured data generation operation
    func executeStructured<T: Generable>(
        prompt: String,
        type: T.Type,
        instructions: String? = nil,
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
        lastTokenCount = nil

        addToHistory(prompt)

        do {
            let session: LanguageModelSession
            if let instructions, !instructions.isEmpty {
                session = LanguageModelSession(instructions: Instructions(instructions))
            } else {
                session = LanguageModelSession()
            }
            let response = try await session.respond(
                to: Prompt(prompt),
                generating: type
            )

            result = formatter(response.content)

            lastTokenCount = await session.transcript.tokenCount()

        } catch {
            errorMessage = FoundationModelsErrorHandler.handleError(error)
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
        lastTokenCount = nil

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
                result = partialResponse.content
                onPartialResult(partialResponse.content)
            }

            lastTokenCount = await session.transcript.tokenCount()

        } catch {
            errorMessage = FoundationModelsErrorHandler.handleError(error)
        }

        isRunning = false
    }

    /// Clears all state
    func clear() {
        isRunning = false
        result = ""
        errorMessage = nil
        successMessage = nil
        lastTokenCount = nil
    }

    /// Clears all state including prompt history
    func clearAll() {
        clear()
        promptHistory = []
    }

    /// Adds a prompt to history
    private func addToHistory(_ prompt: String) {
        promptHistory.removeAll { $0 == prompt }
        promptHistory.insert(prompt, at: 0)
        if promptHistory.count > 10 {
            promptHistory = Array(promptHistory.prefix(10))
        }
    }
}
