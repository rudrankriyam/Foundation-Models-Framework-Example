//
//  MurmerViewModel.swift
//  Murmer
//
//  Created by Rudrank Riyam on 6/26/25.
//

import Combine
import EventKit
import Foundation
import FoundationModels
import SwiftUI

#if os(iOS)
import UIKit
#endif

@MainActor
class MurmerViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isListening = false
    @Published var recognizedText = ""
    @Published var selectedList = "Default"
    @Published var availableLists: [String] = ["Default"]
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var lastCreatedReminder: String = ""
    @Published var partialText: String = ""

    // MARK: - Services

    let speechRecognizer: SpeechRecognizer
    let speechSynthesizer: SpeechSynthesizer
    let inferenceService: InferenceService
    let permissionService: PermissionService

    // MARK: - Private Properties

    private let stateMachine: SpeechRecognitionStateMachine
    private let eventStore = EKEventStore()

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        self.speechRecognizer = SpeechRecognizer()
        self.speechSynthesizer = SpeechSynthesizer()
        self.inferenceService = InferenceService()
        self.permissionService = PermissionService()

        self.stateMachine = SpeechRecognitionStateMachine(
            speechRecognitionService: speechRecognizer,
            speechSynthesisService: speechSynthesizer,
            inferenceService: inferenceService,
            permissionService: permissionService
        )

        setupBindings()
        loadReminderLists()
    }

    // For testing with dependency injection
    init(
        speechRecognizer: SpeechRecognizer,
        speechSynthesizer: SpeechSynthesizer,
        inferenceService: InferenceService,
        permissionService: PermissionService
    ) {
        self.speechRecognizer = speechRecognizer
        self.speechSynthesizer = speechSynthesizer
        self.inferenceService = inferenceService
        self.permissionService = permissionService

        self.stateMachine = SpeechRecognitionStateMachine(
            speechRecognitionService: speechRecognizer,
            speechSynthesisService: speechSynthesizer,
            inferenceService: inferenceService,
            permissionService: permissionService
        )

        setupBindings()
        loadReminderLists()
    }

    private func setupBindings() {
        // Bind to state machine state changes
        stateMachine.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }

                self.handleStateMachineStateChange(state)
            }
            .store(in: &cancellables)

        // Bind to speech recognizer state changes for partial text
        speechRecognizer.$state
            .receive(on: DispatchQueue.main)
            .map { $0.partialText }
            .assign(to: &$partialText)
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
            try? await Task.sleep(nanoseconds: 2_000_000_000)
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
