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
    @Published var showSuccess = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var lastCreatedReminder: String = ""

    // MARK: - Private Properties

    private let stateMachine: SpeechRecognitionStateMachine
    let permissionService: PermissionService
    private let eventStore = EKEventStore()

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    var speechRecognizer: SpeechRecognizer {
        DependencyContainer.shared.makeSpeechRecognitionService() as! SpeechRecognizer
    }

    // MARK: - Initialization

    init(
        stateMachine: SpeechRecognitionStateMachine? = nil,
        permissionService: PermissionService? = nil
    ) {
        // Use dependency injection or fall back to container
        let container = DependencyContainer.shared

        self.stateMachine = stateMachine ?? SpeechRecognitionStateMachine(
            speechRecognitionService: container.speechRecognitionService,
            speechSynthesisService: container.speechSynthesisService,
            inferenceService: container.inferenceService,
            permissionService: container.permissionService
        )

        self.permissionService = permissionService ?? (container.permissionService as! PermissionService)

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
    }

    private func handleStateMachineStateChange(_ state: SpeechRecognitionStateMachine.State) {
        print("🔄 STATE MACHINE CHANGED: \(state)")

        switch state {
        case .idle:
            isListening = false
            recognizedText = ""
            hideSuccess()

        case .listening:
            isListening = true

        case .processingSpeech(let text):
            recognizedText = text
            isListening = false

        case .synthesizingResponse(let response):
            lastCreatedReminder = response
            showSuccessAnimation()

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
        showSuccess = false
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

    private func showSuccessAnimation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showSuccess = true
        }

        #if os(iOS)
        provideHapticFeedback(.success)
        #endif

        // Hide after delay
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)  // 3 seconds
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self?.showSuccess = false
                }
            }
        }
    }

    private func hideSuccess() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showSuccess = false
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
            try? await Task.sleep(nanoseconds: 5_000_000_000)  // 5 seconds
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
