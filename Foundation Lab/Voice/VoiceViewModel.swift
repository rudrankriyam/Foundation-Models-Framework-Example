//
//  VoiceViewModel.swift
//  Foundation Lab
//
//  Created by Rudrank Riyam on 10/27/25.
//

import EventKit
import Foundation
import FoundationModels
import SwiftUI
import OSLog
import Speech

#if os(iOS)
import UIKit
#endif

@Observable
@MainActor
class VoiceViewModel {
    // MARK: - Observable Properties

    var isListening = false
    var recognizedText = ""
    var selectedList = "Default" {
        didSet {
            VoiceContext.selectedReminderList = selectedList
        }
    }
    var availableLists: [String] = ["Default"]
    var showError = false
    var errorMessage = ""
    var lastCreatedReminder: String = ""
    var partialText: String = ""

    // MARK: - Permission State (Observable)
    var allPermissionsGranted = false
    var showPermissionAlert = false
    var permissionAlertMessage = ""
    var microphonePermissionStatus: MicrophonePermissionStatus = .undetermined
    var speechPermissionStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    var remindersPermissionStatus: EKAuthorizationStatus = .notDetermined

    var hasRemindersAccess: Bool {
        return remindersPermissionStatus == .fullAccess || remindersPermissionStatus == .writeOnly
    }

    // MARK: - Services

    let speechRecognizer: SpeechRecognizer
    let speechSynthesizer: SpeechSynthesizer
    let inferenceService: InferenceService
    let permissionManager: PermissionManager

    // MARK: - Private Properties

    private let stateMachine: SpeechRecognitionStateMachine
    private let logger = VoiceLogging.state
    private let eventStore = EKEventStore()

    private var recognitionHandlerToken: UUID?

    // MARK: - Initialization

    init() {
        self.speechRecognizer = SpeechRecognizer()
        self.speechSynthesizer = SpeechSynthesizer.shared
        self.inferenceService = InferenceService()
        self.permissionManager = PermissionManager()

        self.stateMachine = SpeechRecognitionStateMachine(
            speechRecognitionService: speechRecognizer,
            speechSynthesisService: speechSynthesizer,
            inferenceService: inferenceService,
            permissionService: permissionManager
        )

        VoiceContext.selectedReminderList = selectedList
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

        VoiceContext.selectedReminderList = selectedList
        setupBindings()
        loadReminderLists()
    }

    func tearDown() {
        stateMachine.cleanup()
        if let token = recognitionHandlerToken {
            speechRecognizer.removeStateChangeHandler(token)
            recognitionHandlerToken = nil
        }
    }

    private func setupBindings() {
        stateMachine.onStateChange = { [weak self] state in
            self?.handleStateMachineStateChange(state)
        }

        recognitionHandlerToken = speechRecognizer.addStateChangeHandler { [weak self] recognitionState in
            guard let self else { return }

            switch recognitionState {
            case .listening(let partial):
                self.partialText = partial

            case .completed(let finalText):
                self.partialText = ""
                if !finalText.isEmpty {
                    self.recognizedText = finalText
                }

            case .error(let error):
                self.partialText = ""
                self.showError(error.localizedDescription)

            case .idle:
                self.partialText = ""
            }
        }
    }

    private func handleStateMachineStateChange(_ state: SpeechRecognitionStateMachine.State) {
        logger.debug("State machine changed: \(String(describing: state))")

        switch state {
        case .idle:
            isListening = false

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
        logger.info("Start listening requested")

        // Reset UI state
        showError = false
        partialText = ""
        recognizedText = ""

        // Delegate to state machine
        await stateMachine.startWorkflow()
    }

    func stopListening() {
        logger.info("Stop listening requested")

        // Delegate to state machine
        stateMachine.stopWorkflow()
    }

    // MARK: - UI Feedback Methods

    func loadReminderLists() {
        Task {
            let calendars = eventStore.calendars(for: .reminder)
            let listNames = calendars.map { $0.title }.sorted()

            await MainActor.run {
                var uniqueLists = ["Default"]
                for name in listNames where !uniqueLists.contains(name) {
                    uniqueLists.append(name)
                }
                self.availableLists = uniqueLists

                if let preferred = uniqueLists.first(where: { $0 == VoiceContext.selectedReminderList }) {
                    self.selectedList = preferred
                } else if let defaultList = calendars.first?.title {
                    self.selectedList = defaultList
                }
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

    // MARK: - Permission Methods

    func checkAllPermissions() {
        permissionManager.checkAllPermissions()
        syncPermissionState()
    }

    func requestAllPermissions() async -> Bool {
        let granted = await permissionManager.requestAllPermissions()
        syncPermissionState()
        return granted
    }

    func showSettingsAlert() {
        permissionManager.showSettingsAlert()
        syncPermissionState()
    }

    func openSettings() {
        permissionManager.openSettings()
    }

    private func syncPermissionState() {
        // Sync permission state from service to observable properties
        let previousRemindersStatus = remindersPermissionStatus
        allPermissionsGranted = permissionManager.allPermissionsGranted
        showPermissionAlert = permissionManager.showPermissionAlert
        permissionAlertMessage = permissionManager.permissionAlertMessage
        microphonePermissionStatus = permissionManager.microphonePermissionStatus
        speechPermissionStatus = permissionManager.speechPermissionStatus
        remindersPermissionStatus = permissionManager.remindersPermissionStatus

        if !isRemindersPermissionGranted(previousRemindersStatus) && hasRemindersAccess {
            loadReminderLists()
        }
    }

    private func isRemindersPermissionGranted(_ status: EKAuthorizationStatus) -> Bool {
        status == .fullAccess || status == .writeOnly
    }
}
