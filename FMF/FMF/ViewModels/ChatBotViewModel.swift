//
//  ChatBotViewModel.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/9/25.
//

import Foundation
import FoundationModels
import Observation

@Observable
final class ChatBotViewModel {

  // MARK: - Published Properties

  var isLoading: Bool = false
  var isSummarizing: Bool = false
  var sessionCount: Int = 1

  // MARK: - Public Properties
  
  private(set) var session: LanguageModelSession

  // MARK: - Initialization

  init() {
    self.session = LanguageModelSession(
      instructions: Instructions(
        "You are a helpful, friendly AI assistant. Engage in natural conversation and provide thoughtful, detailed responses."
      )
    )
  }

  // MARK: - Public Methods

  @MainActor
  func sendMessage(_ content: String) async {
    isLoading = session.isResponding

    do {
      // Stream response from current session
      let responseStream = try session.streamResponse(to: Prompt(content))

      for try await chunk in responseStream {
        // The streaming automatically updates the session transcript
      }

    } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
      // Handle context window exceeded by summarizing and creating new session
      await handleContextWindowExceeded(userMessage: content)

    } catch {
      // For errors, we'll need to manually add an error message to show in UI
      // This is handled in the computed property by checking for incomplete responses
    }

    isLoading = session.isResponding
  }

  @MainActor
  func clearChat() {
    sessionCount = 1
    session = LanguageModelSession(
      instructions: Instructions(
        "You are a helpful, friendly AI assistant. Engage in natural conversation and provide thoughtful, detailed responses."
      )
    )
  }

  // MARK: - Private Methods

  @MainActor
  private func handleContextWindowExceeded(userMessage: String) async {
    isSummarizing = true
    
    do {
      let summary = try await generateConversationSummary()
      createNewSessionWithContext(summary: summary)
      isSummarizing = false
      
      try await respondWithNewSession(to: userMessage)
    } catch {
      handleSummarizationError(error)
    }
  }

  private func createConversationText() -> String {
    return session.transcript.entries.compactMap { entry in
      switch entry {
      case .prompt(let prompt):
        let text = prompt.segments.compactMap { segment in
          if case .text(let textSegment) = segment {
            return textSegment.content
          }
          return nil
        }.joined(separator: " ")
        return "User: \(text)"
      case .response(let response):
        let text = response.segments.compactMap { segment in
          if case .text(let textSegment) = segment {
            return textSegment.content
          }
          return nil
        }.joined(separator: " ")
        return "Assistant: \(text)"
      default:
        return nil
      }
    }.joined(separator: "\n\n")
  }
  
  
  @MainActor
  private func generateConversationSummary() async throws -> ConversationSummary {
    let summarySession = LanguageModelSession(
      instructions: Instructions(
        "You are an expert at summarizing conversations. Create comprehensive summaries that preserve all important context and details."
      )
    )
    
    let conversationText = createConversationText()
    let summaryPrompt = """
      Please summarize the following entire conversation comprehensively. Include all key points, topics discussed, user preferences, and important context that would help continue the conversation naturally:

      \(conversationText)
      """
    
    let summaryResponse = try await summarySession.respond(
      to: Prompt(summaryPrompt),
      generating: ConversationSummary.self
    )
    
    return summaryResponse.content
  }
  
  private func createNewSessionWithContext(summary: ConversationSummary) {
    let contextInstructions = """
      You are a helpful, friendly AI assistant. You are continuing a conversation with a user. Here's a summary of your previous conversation:

      CONVERSATION SUMMARY:
      \(summary.summary)

      KEY TOPICS DISCUSSED:
      \(summary.keyTopics.map { "• \($0)" }.joined(separator: "\n"))

      USER PREFERENCES/REQUESTS:
      \(summary.userPreferences.map { "• \($0)" }.joined(separator: "\n"))

      Continue the conversation naturally, referencing this context when relevant. The user's next message is a continuation of your previous discussion.
      """
    
    session = LanguageModelSession(instructions: Instructions(contextInstructions))
    sessionCount += 1
  }
  
  @MainActor
  private func respondWithNewSession(to userMessage: String) async throws {
    let responseStream = try session.streamResponse(to: Prompt(userMessage))
    
    for try await chunk in responseStream {
      // The streaming automatically updates the session transcript
    }
  }
  
  @MainActor
  private func handleSummarizationError(_ error: Error) {
    isSummarizing = false
    // Error handling could be implemented by adding a synthetic transcript entry
    // or by showing an alert - for now we'll rely on the UI to show the error state
  }
}
