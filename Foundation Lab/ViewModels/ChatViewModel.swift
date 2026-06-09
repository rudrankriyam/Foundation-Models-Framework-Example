//
//  ChatViewModel.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/9/25.
//

import Foundation
import FoundationLabCore
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
    private let conversationEngine: FoundationLabConversationEngine
    var isSummarizing: Bool = false
    var isApplyingWindow: Bool = false
    var sessionCount: Int = 1
    var instructions: String
    var selectedModelRuntime: FoundationLabModelRuntime = .onDevice
    var selectedReasoningLevel: FoundationLabReasoningLevel = .none
    var showsReasoningTrace: Bool = true
    var samplingStrategy: SamplingStrategy = .default
    var topKSamplingValue: Int = 50
    var useFixedSeed: Bool = false
    var usePermissiveGuardrails: Bool = false
    private var samplingSeed: UInt64?
    var errorMessage: String?
    var showError: Bool = false

    // MARK: - Token Usage Tracking

    private(set) var currentTokenCount: Int = 0
    private(set) var maxContextSize: Int = AppConfiguration.TokenManagement.defaultMaxTokens

    var tokenUsageFraction: Double {
        guard maxContextSize > 0 else { return 0 }
        return min(1.0, Double(currentTokenCount) / Double(maxContextSize))
    }

    var modelRuntimeStatus: String {
        switch selectedModelRuntime {
        case .onDevice:
            return "Runs locally with Apple Intelligence."
        case .privateCloudCompute:
            return privateCloudComputeStatus
        }
    }

    var canSelectPrivateCloudCompute: Bool {
        #if compiler(>=6.4)
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *) {
            let model = PrivateCloudComputeLanguageModel()
            return model.isAvailable && !model.quotaUsage.isLimitReached
        }
        #endif

        return false
    }

    var canUseReasoning: Bool {
        selectedModelRuntime == .privateCloudCompute && canSelectPrivateCloudCompute
    }

    // MARK: - Public Properties

    private(set) var session: LanguageModelSession

    // MARK: - Feedback State

    private(set) var feedbackState: [Transcript.Entry.ID: LanguageModelFeedback.Sentiment] = [:]

    // MARK: - Generation Options

    var generationOptions: FoundationLabGenerationOptions {
        switch samplingStrategy {
        case .default:
            return FoundationLabGenerationOptions()
        case .greedy:
            return FoundationLabGenerationOptions(sampling: .greedy)
        case .sampling:
            let seed: UInt64? = useFixedSeed ? (samplingSeed ?? generateAndStoreSeed()) : nil
            return FoundationLabGenerationOptions(
                sampling: .randomTop(topKSamplingValue, seed: seed)
            )
        }
    }

    // MARK: - Initialization

    init(
        permissionManager: PermissionManager? = nil,
        speechSynthesizer: SpeechSynthesisService? = nil
    ) {
        self.permissionManager = permissionManager ?? PermissionManager()
        self.speechSynthesizer = speechSynthesizer ?? SpeechSynthesizer.shared
        self.instructions = Self.defaultInstructions

        let configuration = FoundationLabConversationConfiguration(
            baseInstructions: Self.defaultInstructions,
            summaryInstructions: """
            You are an expert at summarizing conversations. Create comprehensive summaries that \
            preserve all important context and details.
            """,
            summaryPromptPreamble: """
            Please summarize the following entire conversation comprehensively. Include all key points, \
            topics discussed, user preferences, and important context that would help continue the \
            conversation naturally:
            """,
            conversationUserLabel: "User:",
            conversationAssistantLabel: "Assistant:",
            continuationNote: """
            Continue the conversation naturally, referencing this context when relevant. \
            The user's next message is a continuation of your previous discussion.
            """,
            modelUseCase: .general,
            guardrails: .default,
            enableSlidingWindow: true,
            windowThreshold: AppConfiguration.TokenManagement.windowThreshold,
            targetWindowSize: AppConfiguration.TokenManagement.targetWindowSize,
            defaultMaxContextSize: AppConfiguration.TokenManagement.defaultMaxTokens
        )
        let engine = FoundationLabConversationEngine(configuration: configuration)
        self.conversationEngine = engine
        self.session = engine.session

        engine.onStateChange = { [weak self] in
            self?.syncConversationState()
        }
        syncConversationState()

        Task {
            await fetchContextSize()
        }
    }

    // MARK: - Public Methods

    func sendMessage(_ content: String) async {
        isLoading = true
        defer { isLoading = session.isResponding }

        do {
            _ = try await conversationEngine.sendStreamingMessage(
                content,
                generationOptions: generationOptions
            )
            syncConversationState()
        } catch is CancellationError {
            return
        } catch {
            errorMessage = message(for: error)
            showError = true
        }
    }

    func submitFeedback(for entryID: Transcript.Entry.ID, sentiment: LanguageModelFeedback.Sentiment) {
        feedbackState[entryID] = sentiment
        _ = session.logFeedbackAttachment(sentiment: sentiment)
    }

    func getFeedback(for entryID: Transcript.Entry.ID) -> LanguageModelFeedback.Sentiment? {
        feedbackState[entryID]
    }

    func clearChat() {
        conversationEngine.clear()
        feedbackState.removeAll()
        isLoading = false
        errorMessage = nil
        showError = false
        syncConversationState()
    }

    func selectModelRuntime(_ runtime: FoundationLabModelRuntime) {
        guard runtime != selectedModelRuntime else { return }

        if runtime == .privateCloudCompute, !canSelectPrivateCloudCompute {
            errorMessage = privateCloudComputeStatus
            showError = true
            return
        }

        selectedModelRuntime = runtime
        if runtime == .onDevice {
            selectedReasoningLevel = .none
        }
        conversationEngine.rebuild(
            modelRuntime: runtime,
            reasoningLevel: selectedReasoningLevel,
            guardrails: currentGuardrails()
        )
        conversationEngine.setMaxContextSize(provisionalContextSize(for: runtime))
        feedbackState.removeAll()
        isLoading = false
        syncConversationState()

        Task {
            await fetchContextSize(for: runtime)
        }
    }

    func selectReasoningLevel(_ level: FoundationLabReasoningLevel) {
        guard level != selectedReasoningLevel else { return }

        if level != .none, !canUseReasoning {
            errorMessage = "Reasoning levels require PCC on Xcode 27 and an eligible OS 27 runtime."
            showError = true
            return
        }

        selectedReasoningLevel = level
        conversationEngine.rebuild(
            reasoningLevel: level,
            guardrails: currentGuardrails()
        )
        feedbackState.removeAll()
        isLoading = false
        syncConversationState()
    }

    func updateInstructions(_ newInstructions: String) {
        instructions = newInstructions
        conversationEngine.rebuild(
            baseInstructions: newInstructions,
            guardrails: currentGuardrails()
        )
        syncConversationState()
    }

    func dismissError() {
        showError = false
        errorMessage = nil
        if case .error = voiceState {
            voiceState = .idle
        }
    }

    func tearDown() {
        conversationEngine.cancelActiveResponse()
        stopSpeechObservation()
        speechRecognizer?.stopRecognition()
        speechRecognizer = nil
    }

    // MARK: - Voice Methods

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

        conversationEngine.prewarm()

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

    func cancelVoiceMode() {
        stopSpeechObservation()
        voiceState = .idle
        errorMessage = nil
        showError = false
        speechRecognizer?.stopRecognition()
        speechRecognizer = nil
    }

    func stopSpeaking() {
        guard case .speaking = voiceState else { return }
        speechSynthesizer.cancelSpeaking()
        restartListening()
    }

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
            let response = try await conversationEngine.sendMessage(
                trimmedText,
                generationOptions: generationOptions
            )
            syncConversationState()
            voiceState = .speaking(response: response)

            do {
                try await speechSynthesizer.synthesizeAndSpeak(text: response)
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

            restartListening()
        } catch {
            handleVoiceError(error.localizedDescription)
        }
    }
}

private extension ChatViewModel {
    static let defaultInstructions = """
    You are a helpful, friendly AI assistant. Engage in natural conversation and provide
    thoughtful, detailed responses.
    """

    func syncConversationState() {
        session = conversationEngine.session
        selectedModelRuntime = conversationEngine.modelRuntime
        selectedReasoningLevel = conversationEngine.reasoningLevel
        currentTokenCount = conversationEngine.currentTokenCount
        maxContextSize = conversationEngine.maxContextSize
        isSummarizing = conversationEngine.isSummarizing
        isApplyingWindow = conversationEngine.isApplyingWindow
        sessionCount = conversationEngine.sessionCount
    }

    func fetchContextSize(for runtime: FoundationLabModelRuntime? = nil) async {
        let requestedRuntime = runtime ?? selectedModelRuntime
        let requestedGuardrails = currentGuardrails()

        if requestedRuntime == .privateCloudCompute {
            let contextSize = await privateCloudComputeContextSize()
            guard selectedModelRuntime == requestedRuntime else { return }
            conversationEngine.setMaxContextSize(contextSize)
            syncConversationState()
            return
        }

        let contextSize = await AppConfiguration.TokenManagement.contextSize(
            modelUseCase: .general,
            guardrails: requestedGuardrails
        )
        guard selectedModelRuntime == requestedRuntime,
              currentGuardrails() == requestedGuardrails else { return }
        conversationEngine.setMaxContextSize(contextSize)
        syncConversationState()
    }

    func provisionalContextSize(for runtime: FoundationLabModelRuntime) -> Int {
        switch runtime {
        case .onDevice:
            AppConfiguration.TokenManagement.defaultMaxTokens
        case .privateCloudCompute:
            32_768
        }
    }

    // MARK: - Voice Helpers

    func initializeSpeechRecognizer() async -> Bool {
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

    func startSpeechObservation() {
        stopSpeechObservation()
        speechObservationTask = Task { @MainActor [weak self] in
            await self?.observeSpeechState()
        }
    }

    func stopSpeechObservation() {
        speechObservationTask?.cancel()
        speechObservationTask = nil
    }

    func restartListening() {
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

    func handleVoiceError(_ message: String) {
        stopSpeechObservation()
        speechRecognizer?.stopRecognition()
        speechRecognizer = nil
        errorMessage = message
        showError = true
        voiceState = .error(message: message)
    }

    func message(for error: Error) -> String {
        let handledMessage = FoundationModelsErrorHandler.handleError(error)

        guard selectedModelRuntime == .privateCloudCompute else {
            return handledMessage
        }

        if handledMessage.hasPrefix("PCC ") {
            return handledMessage
        }

        let opaqueLanguageModelFailure = handledMessage.contains("LanguageModel-Error error -1")
            || error.localizedDescription.contains("LanguageModel-Error error -1")

        if opaqueLanguageModelFailure {
            return """
            PCC request failed. Private Cloud Compute is available on this device, but this signed app may be missing the PCC entitlement or a matching provisioning profile.

            Confirm com.apple.developer.private-cloud-compute is present, then try again. Details: \(handledMessage)
            """
        }

        return "PCC request failed. \(handledMessage)"
    }

    func observeSpeechState() async {
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

    func currentGuardrails() -> FoundationLabGuardrails {
        usePermissiveGuardrails ? .permissiveContentTransformations : .default
    }

    func generateAndStoreSeed() -> UInt64 {
        let seed = UInt64.random(in: UInt64.min...UInt64.max)
        samplingSeed = seed
        return seed
    }

    var privateCloudComputeStatus: String {
        #if compiler(>=6.4)
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *) {
            let model = PrivateCloudComputeLanguageModel()
            switch model.availability {
            case .available:
                if model.quotaUsage.isLimitReached {
                    return "PCC daily usage limit reached."
                }
                return "Routes requests through Private Cloud Compute."
            case .unavailable(.deviceNotEligible):
                return "This device is not eligible for PCC."
            case .unavailable(.systemNotReady):
                return "PCC is not ready on this system."
            @unknown default:
                return "PCC is currently unavailable."
            }
        }
        #endif

        return "PCC requires Xcode 27 and iOS, macOS, visionOS, or watchOS 27."
    }

    func privateCloudComputeContextSize() async -> Int {
        #if compiler(>=6.4)
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *) {
            let model = PrivateCloudComputeLanguageModel()
            if let contextSize = try? await model.contextSize {
                return contextSize
            }
        }
        #endif

        return 32_768
    }
}
