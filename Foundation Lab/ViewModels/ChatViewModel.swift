//
//  ChatViewModel.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/9/25.
//

import Foundation
import FoundationModels
import Observation
import Speech

enum SamplingStrategy: Int, CaseIterable {
    case `default`
    case greedy
    case sampling
}

/// Voice mode state machine for multi-turn conversations
enum VoiceState: Equatable {
    case idle
    case preparing
    case listening(partialText: String)
    case processing
    case speaking(response: String)
    case error(message: String)

    var isActive: Bool {
        self != .idle
    }
}

@MainActor
@Observable
final class ChatViewModel {

    // MARK: - Published Properties

    var isLoading: Bool = false

    // MARK: - Voice State

    var voiceState: VoiceState = .idle
    private(set) var speechRecognizer: SpeechRecognizer?
    private var observationTask: Task<Void, Never>?
    private let permissionManager = PermissionManager()
    var isSummarizing: Bool = false
    var isApplyingWindow: Bool = false
    var sessionCount: Int = 1
    var instructions: String = """
        You are a helpful, friendly AI assistant. Engage in natural conversation and provide
        thoughtful, detailed responses.
        """
    var samplingStrategy: SamplingStrategy = .default
    var topKSamplingValue: Int = 50
    var useFixedSeed: Bool = false
    var usePermissiveGuardrails: Bool = false
    private var samplingSeed: UInt64?
    var errorMessage: String?
    var showError: Bool = false

    // MARK: - Public Properties

    private(set) var session: LanguageModelSession = LanguageModelSession()

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
            let seed: UInt64? = useFixedSeed ? (samplingSeed ?? generateAndStoreSeed()) : nil
            return GenerationOptions(sampling: .random(top: topKSamplingValue, seed: seed))
        }
    }

    // MARK: - Sliding Window Configuration
    private let maxTokens = AppConfiguration.TokenManagement.maxTokens
    private let windowThreshold = AppConfiguration.TokenManagement.windowThreshold
    private let targetWindowSize = AppConfiguration.TokenManagement.targetWindowSize

    // MARK: - Initialization

    init() {
        // Initialize session with proper language model and instructions
        session = LanguageModelSession(
            model: createLanguageModel(),
            instructions: Instructions(instructions)
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
            errorMessage = FoundationModelsErrorHandler.handleError(error)
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
        isLoading = false
        isSummarizing = false
        isApplyingWindow = false
        errorMessage = nil
        showError = false
        session = LanguageModelSession(
            model: createLanguageModel(),
            instructions: Instructions(instructions)
        )
    }

    @MainActor
    func updateInstructions(_ newInstructions: String) {
        instructions = newInstructions
        // Create a new session with updated instructions
        // Note: The transcript is read-only, so we start fresh with new instructions
        session = LanguageModelSession(
            model: createLanguageModel(),
            instructions: Instructions(instructions)
        )
    }

    @MainActor
    func dismissError() {
        showError = false
        errorMessage = nil
    }

    // MARK: - Voice Methods

    /// Starts inline voice mode for hands-free conversation.
    /// Requests microphone and speech recognition permissions if needed.
    /// Transitions through: idle -> preparing -> listening
    @MainActor
    func startVoiceMode() async {
        // Check permissions first
        if !permissionManager.allPermissionsGranted {
            let granted = await permissionManager.requestAllPermissions()
            if !granted {
                errorMessage = permissionManager.permissionAlertMessage
                showError = true
                return
            }
        }

        isLoading = false
        voiceState = .preparing

        // Pre-warm the model
        session.prewarm()

        // Initialize speech recognizer
        await initializeSpeechRecognizer()

        // Only transition to listening if still in preparing state
        if case .preparing = voiceState {
            voiceState = .listening(partialText: "")
        }

        // Observe speech state changes in the background
        observationTask = Task {
            await observeSpeechState()
        }
    }

    /// Cancels the current voice mode session and resets to idle state.
    /// Clears any error messages and stops speech recognition.
    @MainActor
    func cancelVoiceMode() {
        observationTask?.cancel()
        observationTask = nil
        voiceState = .idle
        errorMessage = nil
        showError = false
        speechRecognizer?.stopRecognition()
        speechRecognizer = nil
    }

    /// Interrupts the AI's speech response and returns to listening mode.
    /// Allows the user to speak immediately without waiting for TTS to finish.
    @MainActor
    func stopSpeaking() {
        if case .speaking = voiceState {
            SpeechSynthesizer.shared.cancelSpeaking()
            voiceState = .listening(partialText: "")
        }
    }

    /// Stops listening and sends the recognized text to the AI.
    /// Sends the voice input to the session, plays TTS response, and
    /// auto-returns to listening for multi-turn conversation.
    @MainActor
    func stopVoiceModeAndSend() async {
        guard case .listening(let text) = voiceState else { return }

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            observationTask?.cancel()
            observationTask = nil
            speechRecognizer?.stopRecognition()
            speechRecognizer = nil
            voiceState = .idle
            return
        }

        if let recognizer = speechRecognizer {
            recognizer.stopRecognition()
        } else {
            errorMessage = "Speech recognizer not initialized"
            showError = true
            voiceState = .error(message: errorMessage!)
            return
        }

        do {
            let response = try await session.respond(to: Prompt(trimmedText))
            voiceState = .speaking(response: response.content)

            do {
                try await SpeechSynthesizer.shared.synthesizeAndSpeak(text: response.content)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                voiceState = .error(message: errorMessage!)
                return
            }

            // Auto-return to listening for multi-turn!
            voiceState = .listening(partialText: "")
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            voiceState = .error(message: errorMessage!)
        }
    }
}

private extension ChatViewModel {
    // MARK: - Voice Helpers

    @MainActor
    private func initializeSpeechRecognizer() async {
        speechRecognizer = SpeechRecognizer()

        do {
            try speechRecognizer?.startRecognition()
        } catch {
            voiceState = .error(message: error.localizedDescription)
        }
    }

    /// Observes speech recognizer state changes and updates voiceState accordingly
    @MainActor
    private func observeSpeechState() async {
        guard let recognizer = speechRecognizer else { return }

        for await state in recognizer.stateValues {
            switch state {
            case .listening(let partialText):
                if case .listening = voiceState {
                    voiceState = .listening(partialText: partialText)
                }
            case .completed(let finalText):
                if case .listening = voiceState {
                    voiceState = .listening(partialText: finalText)
                }
            case .error(let speechError):
                voiceState = .error(message: speechError.localizedDescription)
            case .idle:
                break
            }
        }
    }

    // MARK: - Language Model

    func createLanguageModel() -> SystemLanguageModel {
        let guardrails: SystemLanguageModel.Guardrails = usePermissiveGuardrails ?
            .permissiveContentTransformations : .default
        return SystemLanguageModel(useCase: .general, guardrails: guardrails)
    }

    func generateAndStoreSeed() -> UInt64 {
        let seed = UInt64.random(in: UInt64.min...UInt64.max)
        samplingSeed = seed
        return seed
    }
}

private extension ChatViewModel {
    // MARK: - Sliding Window Implementation

    func shouldApplyWindow() -> Bool {
        session.transcript.isApproachingLimit(threshold: windowThreshold, maxTokens: maxTokens)
    }

    @MainActor
    func applySlidingWindow() async {
        isApplyingWindow = true

        let windowEntries = session.transcript.entriesWithinTokenBudget(targetWindowSize)

        var finalEntries = windowEntries
        if let instructions = session.transcript.first(where: {
            if case .instructions = $0 { return true }
            return false
        }) {
            if !finalEntries.contains(where: { $0.id == instructions.id }) {
                finalEntries.insert(instructions, at: 0)
            }
        }

        let windowedTranscript = Transcript(entries: finalEntries)
        _ = windowedTranscript.estimatedTokenCount

        session = LanguageModelSession(model: createLanguageModel(), transcript: windowedTranscript)
        sessionCount += 1

        isApplyingWindow = false
    }
}

private extension ChatViewModel {
    // MARK: - Error Handling + Context Management

    @MainActor
    func handleContextWindowExceeded(userMessage: String) async {
        isSummarizing = true

        do {
            let summary = try await generateConversationSummary()
            createNewSessionWithContext(summary: summary)
            isSummarizing = false

            try await respondWithNewSession(to: userMessage)
        } catch {
            handleSummarizationError(error)
            errorMessage = FoundationModelsErrorHandler.handleError(error)
            showError = true
        }
    }

    func createConversationText() -> String {
        ConversationContextBuilder.conversationText(
            from: session.transcript,
            userLabel: "User:",
            assistantLabel: "Assistant:"
        )
    }

    @MainActor
    func generateConversationSummary() async throws -> ConversationSummary {
        let summarySession = LanguageModelSession(
            model: createLanguageModel(),
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

    func createNewSessionWithContext(summary: ConversationSummary) {
        let continuationNote = """
        Continue the conversation naturally, referencing this context when relevant. \
        The user's next message is a continuation of your previous discussion.
        """

        let contextInstructions = ConversationContextBuilder.contextInstructions(
            baseInstructions: instructions,
            summary: summary.summary,
            keyTopics: summary.keyTopics,
            userPreferences: summary.userPreferences,
            continuationNote: continuationNote
        )

        session = LanguageModelSession(
            model: createLanguageModel(),
            instructions: Instructions(contextInstructions)
        )
        sessionCount += 1
    }

    @MainActor
    func respondWithNewSession(to userMessage: String) async throws {
        let responseStream = session.streamResponse(to: Prompt(userMessage), options: generationOptions)

        for try await _ in responseStream {
            // The streaming automatically updates the session transcript
        }
    }

    @MainActor
    func handleSummarizationError(_ error: Error) {
        isSummarizing = false
        errorMessage = error.localizedDescription
        showError = true
    }
}
