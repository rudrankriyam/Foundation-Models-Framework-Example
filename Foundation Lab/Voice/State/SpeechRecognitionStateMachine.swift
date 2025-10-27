//
//  SpeechRecognitionStateMachine.swift
//  Foundation Lab
//
//  Created by Rudrank Riyam on 10/27/25.
//

import Foundation
import OSLog

// MARK: - Speech Recognition State Machine

/// State machine for managing speech recognition workflow
@MainActor
final class SpeechRecognitionStateMachine {

    // MARK: - State Definition

    enum State {
        case idle
        case requestingPermission
        case permissionGranted
        case permissionDenied
        case initializingRecognition
        case listening
        case processingSpeech(String) // Contains recognized text
        case synthesizingResponse(String) // Contains response text
        case completed
        case error(SpeechRecognitionStateMachineError)

        var isActive: Bool {
            switch self {
            case .idle, .completed, .error:
                return false
            case .requestingPermission, .permissionGranted, .permissionDenied,
                 .initializingRecognition, .listening, .processingSpeech, .synthesizingResponse:
                return true
            }
        }

        var canStartListening: Bool {
            switch self {
            case .idle, .permissionGranted, .completed:
                return true
            default:
                return false
            }
        }

        var shouldStopListening: Bool {
            switch self {
            case .listening, .processingSpeech:
                return true
            default:
                return false
            }
        }
    }

    // MARK: - Errors

    enum SpeechRecognitionStateMachineError: LocalizedError {
        case permissionDenied
        case recognitionFailed(String)
        case processingFailed(String)
        case synthesisFailed(String)

        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Microphone or speech recognition permission denied"
            case .recognitionFailed(let message):
                return "Speech recognition failed: \(message)"
            case .processingFailed(let message):
                return "Text processing failed: \(message)"
            case .synthesisFailed(let message):
                return "Speech synthesis failed: \(message)"
            }
        }
    }

    // MARK: - Observable Properties

    private(set) var state: State = .idle {
        didSet { notifyStateChange() }
    }

    var onStateChange: ((State) -> Void)?

    // MARK: - Private Properties

    private let speechRecognitionService: SpeechRecognitionService
    private let speechSynthesisService: SpeechSynthesisService
    private let inferenceService: InferenceServiceProtocol
    private let permissionService: PermissionServiceProtocol
    private let logger = VoiceLogging.state

    private var currentSpeechTask: Task<Void, Never>?
    private var speechRecognizerHandlerToken: UUID?
    private var idleResetTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        speechRecognitionService: SpeechRecognitionService,
        speechSynthesisService: SpeechSynthesisService,
        inferenceService: InferenceServiceProtocol,
        permissionService: PermissionServiceProtocol
    ) {
        self.speechRecognitionService = speechRecognitionService
        self.speechSynthesisService = speechSynthesisService
        self.inferenceService = inferenceService
        self.permissionService = permissionService

        setupBindings()
    }

    // MARK: - Public Interface

    func startWorkflow() async {
        if case .synthesizingResponse = state {
            logger.info("Interrupting synthesis to restart workflow")
            speechSynthesisService.cancelSpeaking()
            state = .idle
        } else if case .completed = state {
            state = .idle
        }

        guard state.canStartListening else {
            logger.warning("Cannot start listening from current state: \(String(describing: self.state))")
            return
        }

        logger.info("Starting speech recognition workflow")

        // Check permissions first
        await requestPermissionsIfNeeded()

        // If permissions are granted, start recognition
        if case .permissionGranted = state {
            await startRecognition()
        }
    }

    func stopWorkflow() {
        logger.info("Stopping speech recognition workflow")

        // Cancel any ongoing tasks
        currentSpeechTask?.cancel()
        currentSpeechTask = nil

        // Stop services
        speechRecognitionService.stopRecognition()

        // Reset to idle state
        state = .idle
    }

    // MARK: - Private Methods

    private func setupBindings() {
        speechRecognizerHandlerToken = speechRecognitionService.addStateChangeHandler { [weak self] newState in
            self?.handleSpeechRecognitionStateChange(from: newState)
        }

        speechSynthesisService.speakingStateHandler = { [weak self] isSpeaking in
            self?.handleSpeechSynthesisStateChange(isSpeaking: isSpeaking)
        }

        speechSynthesisService.errorHandler = { [weak self] error in
            self?.handleSynthesisError(error)
        }
    }

    private func handleSpeechRecognitionStateChange(from recognitionState: SpeechRecognitionState) {
        switch recognitionState {
        case .idle:
            // Recognition stopped, check if we should transition
            if case .listening = state {
                state = .idle
            }

        case .listening:
            if case .initializingRecognition = state {
                logger.info("State machine: initializingRecognition → listening")
                state = .listening
            }

        case .completed(let finalText):
            if !finalText.isEmpty {
                logger.info("State machine: listening → processingSpeech with text: \(finalText)")
                state = .processingSpeech(finalText)
                processRecognizedText(finalText)
            } else {
                state = .idle
            }

        case .error(let error):
            logger.error("State machine: speech recognition error: \(error.localizedDescription)")
            state = .error(.recognitionFailed(error.localizedDescription))
            scheduleIdleReset()
        }
    }

    private func handleSpeechSynthesisStateChange(isSpeaking: Bool) {
        guard case .synthesizingResponse = state else { return }

        if !isSpeaking {
            state = .completed
            scheduleIdleReset()
        }
    }

    private func handleSynthesisError(_ error: SpeechSynthesizerError) {
        state = .error(.synthesisFailed(error.localizedDescription))
        scheduleIdleReset()
    }

    private func requestPermissionsIfNeeded() async {
        if permissionService.allPermissionsGranted {
            state = .permissionGranted
            return
        }

        state = .requestingPermission

        let granted = await permissionService.requestAllPermissions()

        if granted {
            state = .permissionGranted
        } else {
            state = .permissionDenied
            state = .error(.permissionDenied)
            scheduleIdleReset()
        }
    }

    private func startRecognition() async {
        state = .initializingRecognition

        do {
            try speechRecognitionService.startRecognition()
            // State will be updated via binding when recognition actually starts
        } catch {
            state = .error(.recognitionFailed(error.localizedDescription))
            scheduleIdleReset()
        }
    }

    private func processRecognizedText(_ text: String) {
        currentSpeechTask = Task { [weak self] in
            guard let self = self else { return }

            do {
                // Process text with AI
                let response = try await self.inferenceService.processText(text)

                // Synthesize response
                self.state = .synthesizingResponse(response)
                try await self.speechSynthesisService.synthesizeAndSpeak(text: response)

            } catch {
                self.state = .error(.processingFailed(error.localizedDescription))
                self.scheduleIdleReset()
            }
        }
    }

    // MARK: - Cleanup

    func cleanup() {
        currentSpeechTask?.cancel()
        currentSpeechTask = nil
        if let token = speechRecognizerHandlerToken {
            speechRecognitionService.removeStateChangeHandler(token)
            speechRecognizerHandlerToken = nil
        }
        idleResetTask?.cancel()
        idleResetTask = nil
        speechSynthesisService.speakingStateHandler = nil
        speechSynthesisService.errorHandler = nil
    }

    private func notifyStateChange() {
        onStateChange?(state)
    }

    private func scheduleIdleReset() {
        idleResetTask?.cancel()
        idleResetTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(0.5))
            self?.state = .idle
        }
    }
}
