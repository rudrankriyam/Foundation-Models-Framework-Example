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

  // Track if recognition was cancelled intentionally
  private var wasCancelled = false

  // Track if we're currently processing text to prevent interference
  private var isProcessingText = false

  let speechRecognizer = SpeechRecognizer()
  let permissionManager = PermissionManager()

  private let inferenceService = InferenceService()
  private let speechSynthesizer = SpeechSynthesizer()
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

        print("🔄 STATE CHANGED: \(state)")

        switch state {
        case .idle:
          print("🔄 Processing .idle state")
          self.isListening = false
          // Clear any partial text when idle
          self.recognizedText = ""

        case .listening(let partialText):
          print("🔄 Processing .listening state: '\(partialText)'")
          self.isListening = true
          self.recognizedText = partialText

        case .completed(let finalText):
          print("🔄 Processing .completed state: '\(finalText)'")
          self.isListening = false
          self.recognizedText = finalText
          // Process the text - the processRecognizedText will handle stopping listening
          print("🔄 Calling processRecognizedText")
          self.processRecognizedText(finalText)

        case .error(let error):
          print("🔄 Processing .error state: \(error.localizedDescription)")
          self.isListening = false
          self.showError(error.localizedDescription)
        }
      }
      .store(in: &cancellables)
  }

  func startListening() async {
    print("📱 START LISTENING CALLED")
    print("📱 Current flags: wasCancelled=\(wasCancelled), isProcessingText=\(isProcessingText)")
    
    // Don't start if we're currently processing text
    guard !isProcessingText else {
      print("📱 SKIPPING: Currently processing text")
      return
    }
    
    guard permissionManager.allPermissionsGranted else {
      let granted = await permissionManager.requestAllPermissions()

      if !granted {
        permissionManager.showSettingsAlert()
        return
      }
      return
    }

    do {
      // Reset cancellation flag when starting new recognition
      print("📱 Resetting flags: wasCancelled=false, isProcessingText=false")
      wasCancelled = false
      isProcessingText = false

      print("📱 Calling speechRecognizer.startRecognition()")
      try speechRecognizer.startRecognition()

      isListening = true
      recognizedText = ""
      showSuccess = false
      showError = false

      print("📱 START LISTENING COMPLETED SUCCESSFULLY")

    } catch {
      print("📱 START LISTENING FAILED: \(error.localizedDescription)")
      showError(error.localizedDescription)
    }
  }

  func stopListening() {
    print("📱 STOP LISTENING CALLED")
    print("📱 Current flags: wasCancelled=\(wasCancelled), isProcessingText=\(isProcessingText)")
    
    print("📱 Setting wasCancelled = true")
    wasCancelled = true
    print("📱 Calling speechRecognizer.stopRecognition()")
    speechRecognizer.stopRecognition()

    isListening = false
    print("📱 STOP LISTENING COMPLETED")
  }

  private func processRecognizedText(_ text: String) {
    print("🧠 PROCESS RECOGNIZED TEXT CALLED: '\(text)'")
    print("🧠 Current flags: wasCancelled=\(wasCancelled), isProcessingText=\(isProcessingText)")
    
    // Don't process empty, whitespace-only, or very short text
    let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !cleanText.isEmpty && cleanText.count >= 3 else {
      print("🧠 SKIPPING: Text too short or empty")
      return
    }

    // Prevent multiple processing attempts
    guard !isProcessingText else {
      print("🧠 SKIPPING: Already processing text")
      return
    }

    print("🧠 STARTING TEXT PROCESSING")

    Task {
      print("🧠 Setting isProcessingText = true")
      isProcessingText = true

      // Ensure we're not listening while processing
      if speechRecognizer.state.isListening {
        print("🧠 Stopping recognition since we're processing")
        speechRecognizer.stopRecognition()
      }

      do {
        print("🧠 Calling inferenceService.processText()")
        // Use the inference service to process the text
        let response = try await inferenceService.processText(cleanText)
        print("🧠 Inference completed: '\(response)'")

        // Store the response for display
        lastCreatedReminder = response

        print("🧠 Starting speech synthesis")
        // Speak the AI response
        try await speechSynthesizer.synthesizeAndSpeak(text: response)
        print("🧠 Speech synthesis completed")

        showSuccessAnimation()
        provideHapticFeedback("success")

        // Clear the recognized text after a delay
        print("🧠 Waiting 2 seconds before clearing text")
        try? await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds
        recognizedText = ""

        print("🧠 TEXT PROCESSING COMPLETED SUCCESSFULLY")

      } catch {
        print("🧠 TEXT PROCESSING FAILED: \(error.localizedDescription)")
        showError("Failed to create reminder: \(error.localizedDescription)")
        provideHapticFeedback("error")
      }

      print("🧠 Resetting flags: isProcessingText=false, wasCancelled=false")
      isProcessingText = false
      wasCancelled = false // Reset cancellation flag after processing
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
