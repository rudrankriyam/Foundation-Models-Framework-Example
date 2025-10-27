//
//  SpeechRecognitionStateMachine.swift
//  Foundation Lab
//
//  Created by Rudrank Riyam on 10/27/25.
//

import Foundation
import Combine

// MARK: - Speech Recognition State Machine

/// State machine for managing speech recognition workflow
@Observable
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
            case .idle, .permissionGranted:
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

    private(set) var state: State = .idle

    // MARK: - Private Properties

    private let speechRecognitionService: SpeechRecognitionService
    private let speechSynthesisService: SpeechSynthesisService
    private let inferenceService: InferenceServiceProtocol
    private let permissionService: PermissionServiceProtocol

    private var cancellables = Set<AnyCancellable>()
    private var currentSpeechTask: Task<Void, Never>?

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
        guard state.canStartListening else {
            print("⚠️ Cannot start listening from current state: \(state)")
            return
        }

        print("🚀 Starting speech recognition workflow")

        // Check permissions first
        await requestPermissionsIfNeeded()

        // If permissions are granted, start recognition
        if case .permissionGranted = state {
            await startRecognition()
        }
    }

    func stopWorkflow() {
        print("🛑 Stopping speech recognition workflow")

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
        // Note: Since we're using @Observable, we'll need to monitor changes differently
        // For now, we'll use Combine with the services if they support it
        // This would need to be adapted based on how the services are implemented
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
                state = .listening
            }

        case .completed(let finalText):
            if !finalText.isEmpty {
                state = .processingSpeech(finalText)
                processRecognizedText(finalText)
            } else {
                state = .idle
            }

        case .error(let error):
            state = .error(.recognitionFailed(error.localizedDescription))
        }
    }

    private func handleSpeechSynthesisStateChange() {
        // Handle synthesis completion
        if !speechSynthesisService.isSpeaking {
            if case .synthesizingResponse = state {
                state = .completed
                // Auto-transition to idle after a delay to allow user to hear the response
                Task { [weak self] in
                    try? await Task.sleep(nanoseconds: 500_000_000) // 500ms delay
                    await MainActor.run {
                        self?.state = .idle
                    }
                }
            }
        }

        // Handle synthesis errors
        if let synthesisError = speechSynthesisService.error {
            state = .error(.synthesisFailed(synthesisError.localizedDescription))
        }
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
        }
    }

    private func startRecognition() async {
        state = .initializingRecognition

        do {
            try speechRecognitionService.startRecognition()
            // State will be updated via binding when recognition actually starts
        } catch {
            state = .error(.recognitionFailed(error.localizedDescription))
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
            }
        }
    }

    // MARK: - Cleanup

    func cleanup() {
        cancellables.forEach { $0.cancel() }
        currentSpeechTask?.cancel()
        currentSpeechTask = nil
    }
}