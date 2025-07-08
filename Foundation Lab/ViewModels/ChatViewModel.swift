//
//  ChatViewModel.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/9/25.
//

import Foundation
import FoundationModels
import Observation

@Observable
final class ChatViewModel {

    // MARK: - Published Properties

    var isLoading: Bool = false
    var isSummarizing: Bool = false
    var sessionCount: Int = 1
    var instructions: String = "You are a helpful, friendly AI assistant. Engage in natural conversation and provide thoughtful, detailed responses."
    var errorMessage: String?
    var showError: Bool = false

    // MARK: - Public Properties

    private(set) var session: LanguageModelSession
    
    // MARK: - Feedback State
    
    private(set) var feedbackState: [Transcript.Entry.ID: LanguageModelFeedbackAttachment.Sentiment] = [:]

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
            let responseStream = session.streamResponse(to: Prompt(content))

            for try await _ in responseStream {
                // The streaming automatically updates the session transcript
            }

        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            // Handle context window exceeded by summarizing and creating new session
            await handleContextWindowExceeded(userMessage: content)

        } catch {
            // Handle other errors by showing an error message
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = session.isResponding
    }

    @MainActor
    func submitFeedback(for entryID: Transcript.Entry.ID, sentiment: LanguageModelFeedbackAttachment.Sentiment) {
        guard let entryIndex = session.transcript.firstIndex(where: { $0.id == entryID }) else {
            // Log error in debug mode only
            #if DEBUG
            print("Error: Could not find transcript entry for feedback.")
            #endif
            return
        }

        // Store the feedback state
        feedbackState[entryID] = sentiment

        let outputEntry = session.transcript[entryIndex]
        let inputEntries = session.transcript[..<entryIndex]

        let feedback = LanguageModelFeedbackAttachment(
            input: Array(inputEntries),
            output: [outputEntry],
            sentiment: sentiment
        )

        // In a real app, you would serialize this and attach it to a Feedback Assistant report.
        // For this example, we'll print the JSON representation to the console.
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(feedback)
            let jsonString = String(data: data, encoding: .utf8) ?? ""
            #if DEBUG
            print("\n--- Feedback Submitted ---")
            print(jsonString)
            print("------------------------\n")
            #endif
        } catch {
            #if DEBUG
            print("Error encoding feedback: \(error)")
            #endif
        }
    }
    
    @MainActor
    func getFeedback(for entryID: Transcript.Entry.ID) -> LanguageModelFeedbackAttachment.Sentiment? {
        return feedbackState[entryID]
    }

    @MainActor
    func clearChat() {
        sessionCount = 1
        feedbackState.removeAll()
        session = LanguageModelSession(
            instructions: Instructions(instructions)
        )
    }
    
    @MainActor
    func updateInstructions(_ newInstructions: String) {
        instructions = newInstructions
        // Create a new session with updated instructions
        // Note: The transcript is read-only, so we start fresh with new instructions
        session = LanguageModelSession(
            instructions: Instructions(instructions)
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
            errorMessage = "Failed to summarize conversation: \(error.localizedDescription)"
            showError = true
        }
    }

    private func createConversationText() -> String {
        return session.transcript.compactMap { entry in
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
      \(instructions)
      
      You are continuing a conversation with a user. Here's a summary of your previous conversation:
      
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
        let responseStream = session.streamResponse(to: Prompt(userMessage))

        for try await _ in responseStream {
            // The streaming automatically updates the session transcript
        }
    }

    @MainActor
    private func handleSummarizationError(_ error: Error) {
        isSummarizing = false
        errorMessage = error.localizedDescription
        showError = true
    }
    
    @MainActor
    func dismissError() {
        showError = false
        errorMessage = nil
    }
}
