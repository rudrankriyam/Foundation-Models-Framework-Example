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

  private let eventStore = EKEventStore()
  private let reminderTool = MurmerRemindersTool()

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
        // Extract time expression
        let timeExpression = extractTimeExpression(from: text)

        // Create reminder using the tool
        let listName = selectedList == "Default" ? nil : selectedList

        let arguments = MurmerRemindersTool.Arguments(
          text: text,
          timeExpression: timeExpression,
          listName: listName
        )

        _ = try await reminderTool.call(arguments: arguments)

        // The tool returns properties directly in the GeneratedContent
        // We can access the success status and title from the output
        lastCreatedReminder = recognizedText  // Use the original text as the reminder title

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

  private func extractTimeExpression(from text: String) -> String? {
    // Common time patterns
    let timePatterns = [
      "tomorrow", "today", "tonight",
      "next week", "next month",
      "in \\d+ (hour|minute|day|week)",
      "at \\d+(:\\d+)? ?(am|pm)?",
      "(monday|tuesday|wednesday|thursday|friday|saturday|sunday)",
    ]

    let lowercased = text.lowercased()

    for pattern in timePatterns {
      if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
        let matches = regex.matches(
          in: lowercased, range: NSRange(lowercased.startIndex..., in: lowercased))

        if let match = matches.first,
          let range = Range(match.range, in: lowercased)
        {
          _ = String(lowercased[range])

          // Extract the time expression and any surrounding context with safe bounds checking
          let safeStartIndex = max(
            lowercased.startIndex,
            lowercased.index(range.lowerBound, offsetBy: -10, limitedBy: lowercased.startIndex)
              ?? lowercased.startIndex)
          let safeEndIndex = min(
            lowercased.endIndex,
            lowercased.index(range.upperBound, offsetBy: 10, limitedBy: lowercased.endIndex)
              ?? lowercased.endIndex)

          let extracted = String(lowercased[safeStartIndex..<safeEndIndex]).trimmingCharacters(
            in: .whitespaces)
          return extracted
        }
      }
    }

    return nil
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
