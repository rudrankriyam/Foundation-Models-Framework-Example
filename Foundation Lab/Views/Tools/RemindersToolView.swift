//
//  RemindersToolView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import FoundationLabCore
import SwiftUI

struct RemindersToolView: View {
  // MARK: - Constants
  private enum Constants {
    static let defaultDateOffset: TimeInterval = 3600  // 1 hour
    static let maxNotesLines = 4
    static let minNotesLines = 2
    static let maxPromptLines = 6
    static let minPromptLines = 3
  }

  // MARK: - State Properties
  @State private var executor = ToolExecutor()

  // Input fields
  @State private var reminderTitle: String = ""
  @State private var reminderNotes: String = ""
  @State private var selectedDate = Date().addingTimeInterval(Constants.defaultDateOffset)
  @State private var hasDueDate = true
  @State private var selectedPriority: ReminderPriority = .none
  @State private var customPrompt: String = ""
  @State private var useCustomPrompt = false

  // MARK: - Body
  var body: some View {
    ToolViewBase(
      title: "Reminders",
      icon: "checklist",
      description: "Create and manage reminders with AI assistance",
      isRunning: executor.isRunning,
      errorMessage: executor.errorMessage
    ) {
      VStack(alignment: .leading, spacing: 20) {
        if let success = executor.successMessage {
          SuccessBanner(message: success)
        }

        inputSection

        if !executor.result.isEmpty {
          ResultDisplay(result: executor.result, isSuccess: executor.errorMessage == nil)
        }
      }
    }
  }

  // MARK: - View Components
  private var inputSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Mode selector
      Picker("Input Mode", selection: $useCustomPrompt) {
        Text("Quick Create").tag(false)
        Text("Custom Prompt").tag(true)
      }
      .pickerStyle(SegmentedPickerStyle())

      if useCustomPrompt {
        customPromptSection
      } else {
        quickCreateSection
      }

      // Action button
      actionButtonView(
        useCustomPrompt: useCustomPrompt,
        isRunning: executor.isRunning,
        action: executeReminder,
        isDisabled: executor.isRunning || (useCustomPrompt ?
          !validateCustomPromptInput(customPrompt: customPrompt) :
          !validateQuickCreateInput(reminderTitle: reminderTitle))
      )
    }
  }

  private var customPromptSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Natural Language Request")
        .font(.headline)

      Text("Describe what you want to do with reminders in natural language")
        .font(.caption)
        .foregroundColor(.secondary)

      TextField(
        "e.g., 'Create a reminder to call mom tomorrow at 2 PM'", text: $customPrompt,
        axis: .vertical
      )
      .textFieldStyle(RoundedBorderTextFieldStyle())
      .lineLimit(Constants.minPromptLines...Constants.maxPromptLines)
    }
  }

  private var quickCreateSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Quick Create")
        .font(.headline)

      // Title field
      VStack(alignment: .leading, spacing: 6) {
        Text("Title *")
          .font(.subheadline)
          .fontWeight(.medium)

        TextField("What do you need to remember?", text: $reminderTitle)
          .textFieldStyle(RoundedBorderTextFieldStyle())
      }

      // Notes field
      VStack(alignment: .leading, spacing: 6) {
        Text("Notes")
          .font(.subheadline)
          .fontWeight(.medium)

        TextField("Additional details (optional)", text: $reminderNotes, axis: .vertical)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .lineLimit(Constants.minNotesLines...Constants.maxNotesLines)
      }

      // Due date section
      VStack(alignment: .leading, spacing: 8) {
        Toggle("Set Due Date", isOn: $hasDueDate)
          .font(.subheadline)
          .fontWeight(.medium)

        if hasDueDate {
          DatePicker(
            "Due Date", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute]
          )
          .datePickerStyle(CompactDatePickerStyle())
        }
      }

      // Priority selector
      VStack(alignment: .leading, spacing: 8) {
        Text("Priority")
          .font(.subheadline)
          .fontWeight(.medium)

        Picker("Priority", selection: $selectedPriority) {
          ForEach(ReminderPriority.allCases, id: \.self) { priority in
            HStack {
              Text(priority.displayName)
              Spacer()
              Text(priority.emoji)
            }
            .tag(priority)
          }
        }
        .pickerStyle(MenuPickerStyle())
      }
    }
  }

  // MARK: - Actions
  private func executeReminder() {
    Task {
      await performReminderAction()
    }
  }

  @MainActor
  private func performReminderAction() async {
    let config = ExecutionConfig(
      useCustomPrompt: useCustomPrompt,
      customPrompt: customPrompt,
      reminderTitle: reminderTitle,
      reminderNotes: reminderNotes,
      hasDueDate: hasDueDate,
      selectedDate: selectedDate,
      selectedPriority: selectedPriority
    )

    await executor.executeCapability(
      successMessage: "Request completed successfully!",
      clearForm: useCustomPrompt ? nil : resetQuickCreateForm
    ) {
      try await ManageRemindersUseCase().execute(makeRequest(from: config))
    }
  }

  @MainActor
  private func resetQuickCreateForm() {
    reminderTitle = ""
    reminderNotes = ""
    selectedDate = Date().addingTimeInterval(Constants.defaultDateOffset)
    selectedPriority = .none
    customPrompt = ""
  }
}

// MARK: - Supporting Types
enum ReminderPriority: String, CaseIterable {
  case none
  case low
  case medium
  case high

  var displayName: String {
    switch self {
    case .none: return "None"
    case .low: return "Low"
    case .medium: return "Medium"
    case .high: return "High"
    }
  }

  var emoji: String {
    switch self {
    case .none: return ""
    case .low: return "🟢"
    case .medium: return "🟡"
    case .high: return "🔴"
    }
  }
}

#Preview {
  NavigationStack {
    RemindersToolView()
  }
}
