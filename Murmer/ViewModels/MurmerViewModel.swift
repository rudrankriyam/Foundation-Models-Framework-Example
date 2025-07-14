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
    print(" MurmerViewModel: Initializing...")
    setupBindings()
    loadReminderLists()
    print(" MurmerViewModel: Initialization complete")
  }

  private func setupBindings() {
    print(" MurmerViewModel: Setting up bindings...")

    // Bind speech recognition text
    speechRecognizer.$recognizedText
      .receive(on: DispatchQueue.main)
      .sink { [weak self] text in
        if !text.isEmpty {
          print(" MurmerViewModel: Received recognized text: '\(text)'")
          self?.recognizedText = text
          print(" MurmerViewModel: State change - recognizedText updated to: '\(text)'")
          self?.processRecognizedText(text)
        }
      }
      .store(in: &cancellables)

    // Handle errors
    speechRecognizer.$error
      .compactMap { $0 }
      .receive(on: DispatchQueue.main)
      .sink { [weak self] error in
        print(" MurmerViewModel: Speech recognizer error received: \(error.localizedDescription)")
        self?.showError(error.localizedDescription)
      }
      .store(in: &cancellables)

    print(" MurmerViewModel: Bindings setup complete")
  }

  func startListening() async {
    print(" MurmerViewModel: startListening() called")

    guard permissionManager.allPermissionsGranted else {
      print(" MurmerViewModel: Not all permissions granted, checking...")
   
      let granted = await permissionManager.requestAllPermissions()
      print(" MurmerViewModel: Permission request result: \(granted)")

      if !granted {
        print(" MurmerViewModel: Permissions denied, showing settings alert")
        permissionManager.showSettingsAlert()
        return
      }
      return
    }

    print(" MurmerViewModel: All permissions granted, starting recognition...")

    do {
      try speechRecognizer.startRecognition()
      print(" MurmerViewModel: Speech recognition started")

      audioManager.startAudioSession()
      print(" MurmerViewModel: Audio session started")

      isListening = true
      print(" MurmerViewModel: State change - isListening: true")

      recognizedText = ""
      print(" MurmerViewModel: State change - recognizedText cleared")

      showSuccess = false
      showError = false
      print(" MurmerViewModel: State change - showSuccess: false, showError: false")

    } catch {
      print(" MurmerViewModel: Error starting listening: \(error.localizedDescription)")
      showError(error.localizedDescription)
    }
  }

  func stopListening() {
    print(" MurmerViewModel: stopListening() called")

    speechRecognizer.stopRecognition()
    print(" MurmerViewModel: Speech recognition stopped")

    audioManager.stopAudioSession()
    print(" MurmerViewModel: Audio session stopped")

    isListening = false
    print(" MurmerViewModel: State change - isListening: false")
  }

  private func processRecognizedText(_ text: String) {
    print(" MurmerViewModel: processRecognizedText() called with text: '\(text)'")

    Task {
      // Stop listening while processing
      print(" MurmerViewModel: Stopping listening for processing...")
      stopListening()

      do {
        // Extract time expression
        let timeExpression = extractTimeExpression(from: text)
        print(" MurmerViewModel: Extracted time expression: \(timeExpression ?? "nil")")

        // Create reminder using the tool
        let listName = selectedList == "Default" ? nil : selectedList
        print(" MurmerViewModel: Using list: '\(selectedList)' (passed as: \(listName ?? "nil"))")

        let arguments = MurmerRemindersTool.Arguments(
          text: text,
          timeExpression: timeExpression,
          listName: listName
        )

        print(" MurmerViewModel: Tool call arguments:")
        print("  - text: '\(arguments.text)'")
        print("  - timeExpression: '\(arguments.timeExpression ?? "nil")'")
        print("  - listName: '\(arguments.listName ?? "nil")'")

        print(" MurmerViewModel: Calling reminder tool...")
        let output = try await reminderTool.call(arguments: arguments)
        print(" MurmerViewModel: Tool call successful")
        print(" MurmerViewModel: Tool output: \(output)")

        // The tool returns properties directly in the GeneratedContent
        // We can access the success status and title from the output
        lastCreatedReminder = recognizedText  // Use the original text as the reminder title
        print(" MurmerViewModel: Set lastCreatedReminder to: '\(lastCreatedReminder)'")

        showSuccessAnimation()
        print(" MurmerViewModel: Showing success animation")

        provideHapticFeedback("success")
        print(" MurmerViewModel: Provided success haptic feedback")

        // Clear the recognized text after a delay
        print(" MurmerViewModel: Waiting 2 seconds before clearing text...")
        try? await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds
        recognizedText = ""
        print(" MurmerViewModel: State change - recognizedText cleared")

      } catch {
        print(" MurmerViewModel: Error in processRecognizedText: \(error)")
        print(" MurmerViewModel: Error type: \(type(of: error))")
        print(" MurmerViewModel: Error localized description: \(error.localizedDescription)")

        showError("Failed to create reminder: \(error.localizedDescription)")
        provideHapticFeedback("error")
        print(" MurmerViewModel: Provided error haptic feedback")
      }
    }
  }

  private func extractTimeExpression(from text: String) -> String? {
    print(" MurmerViewModel: extractTimeExpression() called with text: '\(text)'")

    // Common time patterns
    let timePatterns = [
      "tomorrow", "today", "tonight",
      "next week", "next month",
      "in \\d+ (hour|minute|day|week)",
      "at \\d+(:\\d+)? ?(am|pm)?",
      "(monday|tuesday|wednesday|thursday|friday|saturday|sunday)",
    ]

    print(" MurmerViewModel: Searching with \(timePatterns.count) patterns")

    let lowercased = text.lowercased()
    print(" MurmerViewModel: Lowercased text: '\(lowercased)'")

    for (index, pattern) in timePatterns.enumerated() {
      print(" MurmerViewModel: Trying pattern \(index + 1): '\(pattern)'")

      if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
        let matches = regex.matches(
          in: lowercased, range: NSRange(lowercased.startIndex..., in: lowercased))
        print(" MurmerViewModel: Found \(matches.count) matches for pattern '\(pattern)'")

        if let match = matches.first,
          let range = Range(match.range, in: lowercased)
        {
          let matchedText = String(lowercased[range])
          print(" MurmerViewModel: Matched text: '\(matchedText)'")

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
          print(" MurmerViewModel: Extracted time expression with context: '\(extracted)'")
          return extracted
        }
      }
    }

    print(" MurmerViewModel: No time expression found")
    return nil
  }

  func loadReminderLists() {
    print(" MurmerViewModel: loadReminderLists() called")

    Task {
      let calendars = eventStore.calendars(for: .reminder)
      print(" MurmerViewModel: Found \(calendars.count) reminder calendars")

      let listNames = calendars.map { $0.title }.sorted()
      print(" MurmerViewModel: Calendar names: \(listNames)")

      await MainActor.run {
        self.availableLists = ["Default"] + listNames
        print(" MurmerViewModel: Updated availableLists to: \(self.availableLists)")
      }
    }
  }

  private func showSuccessAnimation() {
    print(" MurmerViewModel: showSuccessAnimation() called")

    withAnimation(.easeInOut(duration: 0.3)) {
      showSuccess = true
      print(" MurmerViewModel: State change - showSuccess: true")
    }

    // Hide after delay
    Task {
      print(" MurmerViewModel: Waiting 3 seconds before hiding success...")
      try? await Task.sleep(nanoseconds: 3_000_000_000)  // 3 seconds
      withAnimation(.easeInOut(duration: 0.3)) {
        showSuccess = false
        print(" MurmerViewModel: State change - showSuccess: false")
      }
    }
  }

  private func showError(_ message: String) {
    print(" MurmerViewModel: showError() called with message: '\(message)'")

    errorMessage = message
    print(" MurmerViewModel: State change - errorMessage: '\(message)'")

    withAnimation(.easeInOut(duration: 0.3)) {
      showError = true
      print(" MurmerViewModel: State change - showError: true")
    }

    // Hide after delay
    Task {
      print(" MurmerViewModel: Waiting 5 seconds before hiding error...")
      try? await Task.sleep(nanoseconds: 5_000_000_000)  // 5 seconds
      withAnimation(.easeInOut(duration: 0.3)) {
        showError = false
        print(" MurmerViewModel: State change - showError: false")
      }
    }
  }

  private func provideHapticFeedback(_ type: String) {
    print(" MurmerViewModel: provideHapticFeedback() called with type: '\(type)'")

    #if os(iOS)
      let generator = UINotificationFeedbackGenerator()
      generator.prepare()
      print(" MurmerViewModel: Haptic generator prepared")

      switch type {
      case "success":
        generator.notificationOccurred(.success)
        print(" MurmerViewModel: Success haptic feedback triggered")
      case "error":
        generator.notificationOccurred(.error)
        print(" MurmerViewModel: Error haptic feedback triggered")
      case "warning":
        generator.notificationOccurred(.warning)
        print(" MurmerViewModel: Warning haptic feedback triggered")
      default:
        print(" MurmerViewModel: Unknown haptic feedback type: '\(type)'")
        break
      }
    #else
      print(" MurmerViewModel: Haptic feedback not available on macOS")
    #endif
  }
}
