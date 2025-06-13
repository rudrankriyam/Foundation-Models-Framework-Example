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

  var messages: [ChatMessage] = []
  var isLoading: Bool = false
  var isSummarizing: Bool = false
  var sessionCount: Int = 1

  // MARK: - Private Properties

  private var session: LanguageModelSession

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
    // Add user message
    let userMessage = ChatMessage(content: content, isFromUser: true)
    messages.append(userMessage)

    // Create placeholder assistant message for streaming
    let assistantMessage = ChatMessage(content: "", isFromUser: false)
    messages.append(assistantMessage)

    let assistantMessageIndex = messages.count - 1
    isLoading = session.isResponding

    do {
      // Stream response from current session
      let responseStream = try session.streamResponse(to: Prompt(content))

      for try await chunk in responseStream {
        // Update the assistant message in real-time
        // chunk already contains the complete response up to this point
        messages[assistantMessageIndex] = ChatMessage(
          id: messages[assistantMessageIndex].id,  // Keep the same ID
          content: chunk,
          isFromUser: false,
          timestamp: messages[assistantMessageIndex].timestamp  // Keep original timestamp
        )
      }

    } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
      // Remove the placeholder message before handling context exceeded
      messages.removeLast()
      // Handle context window exceeded by summarizing and creating new session
      await handleContextWindowExceeded(userMessage: content)

    } catch {
      // Update the placeholder message with error
      messages[assistantMessageIndex] = ChatMessage(
        id: messages[assistantMessageIndex].id,
        content: "Sorry, I encountered an error: \(error.localizedDescription)",
        isFromUser: false,
        timestamp: messages[assistantMessageIndex].timestamp
      )
    }

    isLoading = session.isResponding
  }

  @MainActor
  func clearChat() {
    messages.removeAll()
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
      // Create a temporary session for summarization
      let summarySession = LanguageModelSession(
        instructions: Instructions(
          "You are an expert at summarizing conversations. Create comprehensive summaries that preserve all important context and details."
        )
      )

      // Prepare conversation text for summarization
      let conversationText = createConversationText()

      // Generate structured summary of ALL entries
      let summaryPrompt = """
        Please summarize the following entire conversation comprehensively. Include all key points, topics discussed, user preferences, and important context that would help continue the conversation naturally:

        \(conversationText)
        """

      let summaryResponse = try await summarySession.respond(
        to: Prompt(summaryPrompt),
        generating: ConversationSummary.self
      )

      let summary = summaryResponse.content

      // Create new session with the summary as context
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

      // Add summary message to show context was refreshed
      let summaryMessage = ChatMessage(
        content:
          "I've summarized our conversation to continue with fresh context. Let me respond to your message: \"\(userMessage)\"",
        isFromUser: false,
        isContextSummary: true
      )
      messages.append(summaryMessage)

      isSummarizing = false

      // Now respond to the original user message with the new session using streaming
      let assistantMessage = ChatMessage(content: "", isFromUser: false)
      messages.append(assistantMessage)
      let assistantMessageIndex = messages.count - 1

      let responseStream = try session.streamResponse(to: Prompt(userMessage))

      for try await chunk in responseStream {
        // chunk already contains the complete response up to this point
        messages[assistantMessageIndex] = ChatMessage(
          id: messages[assistantMessageIndex].id,
          content: chunk,
          isFromUser: false,
          timestamp: messages[assistantMessageIndex].timestamp
        )
      }

    } catch {
      isSummarizing = false
      let errorMessage = ChatMessage(
        content:
          "I encountered an error while managing the conversation context: \(error.localizedDescription)",
        isFromUser: false
      )
      messages.append(errorMessage)
    }
  }

  private func createConversationText() -> String {
    return messages.map { message in
      let sender = message.isFromUser ? "User" : "Assistant"
      return "\(sender): \(message.content)"
    }.joined(separator: "\n\n")
  }
}
