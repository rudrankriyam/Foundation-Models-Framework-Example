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

@MainActor
class MurmerViewModel: ObservableObject {
  @Published var isListening = false
  @Published var recognizedText = ""
  @Published var selectedList = "Default"
  @Published var availableLists: [String] = ["Default"]
  @Published var showSuccess = false
  @Published var showError = false
  @Published var errorMessage = ""
  @Published var lastCreatedReminder: String = ""

  let audioManager = AudioManager()
  let speechRecognizer = SpeechRecognizer()
  let permissionManager = PermissionManager()
  
  private let inferenceService = InferenceService()
  private let eventStore = EKEventStore()

  private var cancellables = Set<AnyCancellable>()

  init() {
    setupBindings()
    loadReminderLists()
  }

  private func setupBindings() {
    // Bind to speech recognition state
    speechRecognizer.$state
      .receive(on: DispatchQueue.main)
      .sink { [weak self] state in
        guard let self = self else { return }

        switch state {
        case .idle:
          self.isListening = false

        case .listening(let partialText):
          self.isListening = true
          self.recognizedText = partialText

        case .completed(let finalText):
          self.isListening = false
          self.recognizedText = finalText
          self.processRecognizedText(finalText)

        case .error(let error):
          self.isListening = false
          self.showError(error.localizedDescription)
        }
      }
      .store(in: &cancellables)
  }

  func startListening() async {
    guard permissionManager.allPermissionsGranted else {
      let granted = await permissionManager.requestAllPermissions()

      if !granted {
        permissionManager.showSettingsAlert()
        return
      }
      return
    }

    do {
      try speechRecognizer.startRecognition()
      audioManager.startAudioSession()

      isListening = true
      recognizedText = ""
      showSuccess = false
      showError = false

    } catch {
      showError(error.localizedDescription)
    }
  }

  func stopListening() {
    speechRecognizer.stopRecognition()
    audioManager.stopAudioSession()

    isListening = false
  }

  private func processRecognizedText(_ text: String) {
    Task {
      // Stop listening while processing
      stopListening()

      do {
        // Use the inference service to process the text
        let response = try await inferenceService.processText(text)
        
        // Store the response for display
        lastCreatedReminder = response

        showSuccessAnimation()
        provideHapticFeedback("success")

        // Clear the recognized text after a delay
        try? await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds
        recognizedText = ""

      } catch {
        showError("Failed to create reminder: \(error.localizedDescription)")
        provideHapticFeedback("error")
      }
    }
  }


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

    // Hide after delay
    Task {
      try? await Task.sleep(nanoseconds: 3_000_000_000)  // 3 seconds
      withAnimation(.easeInOut(duration: 0.3)) {
        showSuccess = false
      }
    }
  }

  private func showError(_ message: String) {
    errorMessage = message

    withAnimation(.easeInOut(duration: 0.3)) {
      showError = true
    }

    // Hide after delay
    Task {
      try? await Task.sleep(nanoseconds: 5_000_000_000)  // 5 seconds
      withAnimation(.easeInOut(duration: 0.3)) {
        showError = false
      }
    }
  }

  private func provideHapticFeedback(_ type: String) {
    #if os(iOS)
      let generator = UINotificationFeedbackGenerator()
      generator.prepare()

      switch type {
      case "success":
        generator.notificationOccurred(.success)
      case "error":
        generator.notificationOccurred(.error)
      case "warning":
        generator.notificationOccurred(.warning)
      default:
        break
      }
    #endif
  }
}
