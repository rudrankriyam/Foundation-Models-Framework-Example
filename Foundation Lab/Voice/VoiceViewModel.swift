//
//  VoiceViewModel.swift
//  Foundation Lab
//
//  Created by Rudrank Riyam on 10/27/25.
//

import Combine
import EventKit
import Foundation
import FoundationModels
import SwiftUI

#if os(iOS)
import UIKit
#endif

@Observable
@MainActor
class VoiceViewModel {
    // MARK: - Observable Properties

    var isListening = false
    var recognizedText = ""
    var selectedList = "Default"
    var availableLists: [String] = ["Default"]
    var showError = false
    var errorMessage = ""
    var lastCreatedReminder: String = ""
    var partialText: String = ""

    // MARK: - Services

    let speechRecognizer: SpeechRecognizer
    let speechSynthesizer: SpeechSynthesizer
    let inferenceService: InferenceService
    let permissionManager: PermissionManager

    // MARK: - Private Properties

    private let stateMachine: SpeechRecognitionStateMachine
    private let eventStore = EKEventStore()

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        self.speechRecognizer = SpeechRecognizer()
        self.speechSynthesizer = SpeechSynthesizer()
        self.inferenceService = InferenceService()
        self.permissionManager = PermissionManager()

        self.stateMachine = SpeechRecognitionStateMachine(
            speechRecognitionService: speechRecognizer,
            speechSynthesisService: speechSynthesizer,
            inferenceService: inferenceService,
            permissionService: permissionManager
        )

        setupBindings()
        loadReminderLists()
    }

    // For testing with dependency injection
    init(
        speechRecognizer: SpeechRecognizer,
        speechSynthesizer: SpeechSynthesizer,
        inferenceService: InferenceService,
        permissionManager: PermissionManager
    ) {
        self.speechRecognizer = speechRecognizer
        self.speechSynthesizer = speechSynthesizer
        self.inferenceService = inferenceService
        self.permissionManager = permissionManager

        self.stateMachine = SpeechRecognitionStateMachine(
            speechRecognitionService: speechRecognizer,
            speechSynthesisService: speechSynthesizer,
            inferenceService: inferenceService,
            permissionService: permissionManager
        )

        setupBindings()
        loadReminderLists()
    }

    private func setupBindings() {
        // Bind to speech recognizer state changes for partial text
        // Note: Since we're using @Observable, we'll need to monitor changes differently
        // This would need to be adapted based on how the services are implemented
    }

    private func handleStateMachineStateChange(_ state: SpeechRecognitionStateMachine.State) {
        print("🔄 STATE MACHINE CHANGED: \(state)")

        switch state {
        case .idle:
            isListening = false
            recognizedText = ""

        case .listening:
            isListening = true

        case .processingSpeech(let text):
            recognizedText = text
            isListening = false

        case .synthesizingResponse(let response):
            lastCreatedReminder = response

        case .completed:
            isListening = false

        case .error(let error):
            isListening = false
            showError(error.localizedDescription)
        default:
            break // Handle other states as needed
        }
    }

    // MARK: - Public Interface

    func startListening() async {
        print("📱 START LISTENING CALLED")

        // Reset UI state
        showError = false

        // Delegate to state machine
        await stateMachine.startWorkflow()
    }

    func stopListening() {
        print("📱 STOP LISTENING CALLED")

        // Delegate to state machine
        stateMachine.stopWorkflow()
    }

    // MARK: - UI Feedback Methods

    func loadReminderLists() {
        Task {
            let calendars = eventStore.calendars(for: .reminder)
            let listNames = calendars.map { $0.title }.sorted()

            await MainActor.run {
                self.availableLists = ["Default"] + listNames
            }
        }
    }

    private func showError(_ message: String) {
        errorMessage = message

        withAnimation(.easeInOut(duration: 0.3)) {
            showError = true
        }

#if os(iOS)
        provideHapticFeedback(.error)
#endif

        // Hide after delay
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self?.showError = false
                }
            }
        }
    }

#if os(iOS)
    private func provideHapticFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
#endif
}