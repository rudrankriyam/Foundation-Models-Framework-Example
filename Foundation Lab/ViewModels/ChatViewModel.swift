//
//  ChatViewModel.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/9/25.
//

import Foundation
import FoundationModels
import Observation

enum SamplingStrategy: Int, CaseIterable {
    case `default`
    case greedy
    case sampling
}

@Observable
final class ChatViewModel {

    // MARK: - Published Properties

    var isLoading: Bool = false
    var isSummarizing: Bool = false
    var isApplyingWindow: Bool = false
    var sessionCount: Int = 1
    var instructions: String = """
        You are a helpful, friendly AI assistant. Engage in natural conversation and provide
        thoughtful, detailed responses.
        """
    var useGreedySampling: Bool = false
    var samplingStrategy: SamplingStrategy = .default
    var topKSamplingValue: Int = 50
    var useRandomSeed: Bool = false
    var errorMessage: String?
    var showError: Bool = false

    // MARK: - Public Properties

    private(set) var session: LanguageModelSession

    // MARK: - Feedback State

    private(set) var feedbackState: [Transcript.Entry.ID: LanguageModelFeedback.Sentiment] = [:]

    // MARK: - Generation Options

    var generationOptions: GenerationOptions {
        switch samplingStrategy {
        case .default:
            return GenerationOptions()
        case .greedy:
            return GenerationOptions(sampling: .greedy)
        case .sampling:
            let seed: UInt64? = useRandomSeed ? UInt64.random(in: UInt64.min...UInt64.max) : nil
            return GenerationOptions(sampling: .random(top: topKSamplingValue, seed: seed))
        }
    }

    // MARK: - Sliding Window Configuration
    private let maxTokens = AppConfiguration.TokenManagement.maxTokens
    private let windowThreshold = AppConfiguration.TokenManagement.windowThreshold
    private let targetWindowSize = AppConfiguration.TokenManagement.targetWindowSize

    // MARK: - Initialization

    init() {
        self.session = LanguageModelSession(
            instructions: Instructions(
                "You are a helpful, friendly AI assistant. Engage in natural conversation and provide " +
                "thoughtful, detailed responses."
            )
        )
    }

    // MARK: - Public Methods

    @MainActor
    func sendMessage(_ content: String) async {
        isLoading = true
        defer { isLoading = session.isResponding }

        do {
            // Check if we need to apply sliding window BEFORE sending
            if shouldApplyWindow() {
                await applySlidingWindow()
            }

            // Stream response from current session
            let responseStream = session.streamResponse(to: Prompt(content), options: generationOptions)

            for try await _ in responseStream {
                // The streaming automatically updates the session transcript
            }

        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            // Fallback: Handle context window exceeded by summarizing and creating new session
            await handleContextWindowExceeded(userMessage: content)

        } catch {
            // Handle other errors by showing an error message
            errorMessage = handleFoundationModelsError(error)
            showError = true
        }
    }

    @MainActor
    func submitFeedback(for entryID: Transcript.Entry.ID, sentiment: LanguageModelFeedback.Sentiment) {
        // Store the feedback state
        feedbackState[entryID] = sentiment

        // Use the new session method to log feedback attachment
        // The return value is Data containing the feedback attachment (can be saved/submitted to Apple)
        let feedbackData = session.logFeedbackAttachment(sentiment: sentiment)
        // Note: feedbackData could be saved to a file for submission to Feedback Assistant if needed
        _ = feedbackData // Explicitly acknowledge we're using the return value
    }

    @MainActor
    func getFeedback(for entryID: Transcript.Entry.ID) -> LanguageModelFeedback.Sentiment? {
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

    // MARK: - Sliding Window Implementation

    private func shouldApplyWindow() -> Bool {
        return session.transcript.isApproachingLimit(threshold: windowThreshold, maxTokens: maxTokens)
    }

    @MainActor
    private func applySlidingWindow() async {
        isApplyingWindow = true

        // Get entries that fit within our target window size
        let windowEntries = session.transcript.entriesWithinTokenBudget(targetWindowSize)

        // Always preserve instructions at the beginning
        var finalEntries = windowEntries
        if let instructions = session.transcript.first(where: {
            if case .instructions = $0 { return true }
            return false
        }) {
            if !finalEntries.contains(where: { $0.id == instructions.id }) {
                finalEntries.insert(instructions, at: 0)
            }
        }

        // Create new session with windowed transcript
        let windowedTranscript = Transcript(entries: finalEntries)
        _ = windowedTranscript.estimatedTokenCount

        session = LanguageModelSession(transcript: windowedTranscript)

        sessionCount += 1

        isApplyingWindow = false
    }

    // MARK: - Private Methods (Existing)

    private func handleFoundationModelsError(_ error: Error) -> String {
        if let generationError = error as? LanguageModelSession.GenerationError {
            return FoundationModelsErrorHandler.handleGenerationError(generationError)
        } else if let toolCallError = error as? LanguageModelSession.ToolCallError {
            return FoundationModelsErrorHandler.handleToolCallError(toolCallError)
        } else if let customError = error as? FoundationModelsError {
            return customError.localizedDescription
        } else {
            return "Error: \(error)"
        }
    }

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
            errorMessage = handleFoundationModelsError(error)
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
                "You are an expert at summarizing conversations. Create comprehensive summaries that " +
                "preserve all important context and details."
            )
        )

        let conversationText = createConversationText()
        let summaryPrompt = """
      Please summarize the following entire conversation comprehensively. Include all key points, topics discussed, \
      user preferences, and important context that would help continue the conversation naturally:

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
      \(summary.userPreferences.map { "• \($0)" }
        .joined(separator: "\n"))

      Continue the conversation naturally, referencing this context when relevant. \
      The user's next message is a continuation of your previous discussion.
      """

        session = LanguageModelSession(instructions: Instructions(contextInstructions))
        sessionCount += 1
    }

    @MainActor
    private func respondWithNewSession(to userMessage: String) async throws {
        let responseStream = session.streamResponse(to: Prompt(userMessage), options: generationOptions)

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
