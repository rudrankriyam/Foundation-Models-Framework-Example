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

@MainActor
@Observable
final class ChatViewModel {

    // MARK: - Published Properties

    var isLoading: Bool = false

    // MARK: - Voice State

    var voiceState: VoiceState = .idle
    private(set) var speechRecognizer: SpeechRecognizer?
    private var speechObservationTask: Task<Void, Never>?
    private let permissionManager: PermissionManager
    private let speechSynthesizer: SpeechSynthesisService
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

    // MARK: - Token Usage Tracking

    /// Current token usage for the transcript. Updated after each message.
    private(set) var currentTokenCount: Int = 0

    /// Maximum context size for the model.
    private(set) var maxContextSize: Int = AppConfiguration.TokenManagement.defaultMaxTokens

    /// Fraction of context window used (0.0 to 1.0).
    var tokenUsageFraction: Double {
        guard maxContextSize > 0 else { return 0 }
        return min(1.0, Double(currentTokenCount) / Double(maxContextSize))
    }

    // MARK: - Streaming Task

    private var streamingTask: Task<Void, Error>?

    // MARK: - Public Properties

    private(set) var session: LanguageModelSession = LanguageModelSession()
    private var languageModel: SystemLanguageModel = SystemLanguageModel(useCase: .general)

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
    private let windowThreshold = AppConfiguration.TokenManagement.windowThreshold
    private let targetWindowSize = AppConfiguration.TokenManagement.targetWindowSize

    // MARK: - Initialization

    init(
        permissionManager: PermissionManager? = nil,
        speechSynthesizer: SpeechSynthesisService? = nil
    ) {
        self.permissionManager = permissionManager ?? PermissionManager()
        self.speechSynthesizer = speechSynthesizer ?? SpeechSynthesizer.shared
        languageModel = createLanguageModel()
        session = LanguageModelSession(
            model: languageModel,
            instructions: Instructions(instructions)
        )

        Task {
            await fetchContextSize()
        }
    }

    // MARK: - Public Methods

    @MainActor
    func sendMessage(_ content: String) async {
        isLoading = true
        defer { isLoading = session.isResponding }

        do {
            if await shouldApplyWindow() {
                await applySlidingWindow()
            }

            let responseStream = session.streamResponse(to: Prompt(content), options: generationOptions)

            streamingTask?.cancel()
            let task = Task { @MainActor in
                for try await _ in responseStream {
                    // The streaming automatically updates the session transcript
                }
            }
            streamingTask = task
            defer { streamingTask = nil }
            do {
                try await task.value
            } catch is CancellationError {
                // User-initiated cancellation (e.g. navigating away).
                return
            }

            await updateTokenCount()

        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            await handleContextWindowExceeded(userMessage: content)

        } catch {
            errorMessage = FoundationModelsErrorHandler.handleError(error)
            showError = true
        }
    }

    @MainActor
    func submitFeedback(for entryID: Transcript.Entry.ID, sentiment: LanguageModelFeedback.Sentiment) {
        feedbackState[entryID] = sentiment

        let feedbackData = session.logFeedbackAttachment(sentiment: sentiment)
        _ = feedbackData
    }

    @MainActor
    func getFeedback(for entryID: Transcript.Entry.ID) -> LanguageModelFeedback.Sentiment? {
        return feedbackState[entryID]
    }

    @MainActor
    func clearChat() {
        streamingTask?.cancel()
        streamingTask = nil
        sessionCount = 1
        feedbackState.removeAll()
        isLoading = false
        isSummarizing = false
        isApplyingWindow = false
        errorMessage = nil
        showError = false
        currentTokenCount = 0
        languageModel = createLanguageModel()
        session = LanguageModelSession(
            model: languageModel,
            instructions: Instructions(instructions)
        )
    }

    @MainActor
    func updateInstructions(_ newInstructions: String) {
        instructions = newInstructions
        languageModel = createLanguageModel()
        session = LanguageModelSession(
            model: languageModel,
            instructions: Instructions(instructions)
        )
        currentTokenCount = 0
    }

    @MainActor
    func dismissError() {
        showError = false
        errorMessage = nil
        if case .error = voiceState {
            voiceState = .idle
        }
    }

    /// Cleans up resources when the view disappears.
    @MainActor
    func tearDown() {
        streamingTask?.cancel()
        streamingTask = nil
        stopSpeechObservation()
        speechRecognizer?.stopRecognition()
        speechRecognizer = nil
    }

    // MARK: - Voice Methods

    @MainActor
    func startVoiceMode() async {
        if case .error = voiceState {
            errorMessage = nil
            showError = false
            voiceState = .idle
        } else if voiceState.isActive {
            return
        }

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

        session.prewarm()

        stopSpeechObservation()
        speechRecognizer?.stopRecognition()
        speechRecognizer = nil

        let didStart = await initializeSpeechRecognizer()
        guard didStart else { return }

        if case .preparing = voiceState {
            voiceState = .listening(partialText: "")
        }

        startSpeechObservation()
    }

    @MainActor
    func cancelVoiceMode() {
        stopSpeechObservation()
        voiceState = .idle
        errorMessage = nil
        showError = false
        speechRecognizer?.stopRecognition()
        speechRecognizer = nil
    }

    @MainActor
    func stopSpeaking() {
        guard case .speaking = voiceState else { return }
        speechSynthesizer.cancelSpeaking()
        restartListening()
    }

    @MainActor
    func stopVoiceModeAndSend() async {
        guard case .listening(let text) = voiceState else { return }

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            cancelVoiceMode()
            return
        }

        guard let recognizer = speechRecognizer else {
            handleVoiceError("Speech recognizer not initialized")
            return
        }
        recognizer.stopRecognition()
        voiceState = .processing

        do {
            let response = try await session.respond(to: Prompt(trimmedText))
            await updateTokenCount()
            voiceState = .speaking(response: response.content)

            do {
                try await speechSynthesizer.synthesizeAndSpeak(text: response.content)
            } catch let synthError as SpeechSynthesizerError {
                if case .cancelled = synthError {
                    return
                }
                handleVoiceError(synthError.localizedDescription)
                return
            } catch {
                handleVoiceError(error.localizedDescription)
                return
            }

            // Auto-return to listening for multi-turn!
            restartListening()
        } catch {
            handleVoiceError(error.localizedDescription)
        }
    }
}

// MARK: - Token Usage

private extension ChatViewModel {
    func fetchContextSize() async {
        maxContextSize = await AppConfiguration.TokenManagement.contextSize(
            for: languageModel
        )
    }

    func updateTokenCount() async {
        currentTokenCount = await session.transcript.tokenCount(
            using: languageModel
        )
    }
}

private extension ChatViewModel {
    // MARK: - Voice Helpers

    @MainActor
    private func initializeSpeechRecognizer() async -> Bool {
        let recognizer = SpeechRecognizer()
        speechRecognizer = recognizer

        do {
            try recognizer.startRecognition()
            return true
        } catch {
            handleVoiceError(error.localizedDescription)
            return false
        }
    }

    @MainActor
    private func startSpeechObservation() {
        stopSpeechObservation()
        speechObservationTask = Task { @MainActor [weak self] in
            await self?.observeSpeechState()
        }
    }

    @MainActor
    private func stopSpeechObservation() {
        speechObservationTask?.cancel()
        speechObservationTask = nil
    }

    @MainActor
    private func restartListening() {
        guard let recognizer = speechRecognizer else {
            handleVoiceError("Speech recognizer not initialized")
            return
        }

        do {
            try recognizer.startRecognition()
            voiceState = .listening(partialText: "")
        } catch {
            handleVoiceError(error.localizedDescription)
        }
    }

    @MainActor
    private func handleVoiceError(_ message: String) {
        stopSpeechObservation()
        speechRecognizer?.stopRecognition()
        speechRecognizer = nil
        errorMessage = message
        showError = true
        voiceState = .error(message: message)
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
                handleVoiceError(speechError.localizedDescription)
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

    func shouldApplyWindow() async -> Bool {
        await session.transcript.isApproachingLimit(
            threshold: windowThreshold,
            maxTokens: maxContextSize,
            using: languageModel
        )
    }

    @MainActor
    func applySlidingWindow() async {
        isApplyingWindow = true

        let model = languageModel
        let windowEntries = await session.transcript.entriesWithinTokenBudget(
            targetWindowSize,
            using: model
        )

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

        session = LanguageModelSession(model: model, transcript: windowedTranscript)
        sessionCount += 1

        await updateTokenCount()

        isApplyingWindow = false
    }
}

private extension ChatViewModel {
    // MARK: - Error Handling + Context Management

    @MainActor
    func handleContextWindowExceeded(userMessage: String) async {
        isSummarizing = true

        let summary: ConversationSummary
        do {
            summary = try await generateConversationSummary()
        } catch {
            handleSummarizationError(error)
            errorMessage = FoundationModelsErrorHandler.handleError(error)
            showError = true
            return
        }

        createNewSessionWithContext(summary: summary)
        isSummarizing = false

        do {
            try await respondWithNewSession(to: userMessage)
            await updateTokenCount()
        } catch {
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
            model: languageModel,
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
            model: languageModel,
            instructions: Instructions(contextInstructions)
        )
        sessionCount += 1
        currentTokenCount = 0
    }

    @MainActor
    func respondWithNewSession(to userMessage: String) async throws {
        let responseStream = session.streamResponse(to: Prompt(userMessage), options: generationOptions)

        streamingTask?.cancel()
        let task = Task { @MainActor in
            for try await _ in responseStream {
                // The streaming automatically updates the session transcript
            }
        }
        streamingTask = task
        defer { streamingTask = nil }
        do {
            try await task.value
        } catch is CancellationError {
            // User-initiated cancellation (e.g. navigating away).
            return
        }
    }

    @MainActor
    func handleSummarizationError(_ error: Error) {
        isSummarizing = false
        errorMessage = error.localizedDescription
        showError = true
    }
}
