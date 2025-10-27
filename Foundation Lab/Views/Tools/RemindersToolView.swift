//
//  RemindersToolView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import FoundationModels
import FoundationModelsTools
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

  // MARK: - Static Properties
  private static let displayDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .full
    formatter.timeStyle = .short
    return formatter
  }()

  private static let apiDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return formatter
  }()

  // MARK: - State Properties
  @State private var executor = ToolExecutor()
  @State private var isRunning = false
  @State private var result: String = ""
  @State private var errorMessage: String?
  @State private var successMessage: String?

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
      isRunning: isRunning,
      errorMessage: errorMessage
    ) {
      VStack(alignment: .leading, spacing: 20) {
        if let success = successMessage {
          SuccessBanner(message: success)
        }

        inputSection

        if !result.isEmpty {
          ResultDisplay(result: result, isSuccess: errorMessage == nil)
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
      Button(action: executeReminder) {
        HStack {
          if isRunning {
            ProgressView()
              .scaleEffect(0.8)
              .foregroundColor(.white)
              .accessibilityLabel("Processing")
          } else {
            Image(systemName: useCustomPrompt ? "bubble.left.and.bubble.right" : "plus")
              .accessibilityHidden(true)
          }

          Text(useCustomPrompt ? "Process Request" : "Create Reminder")
            .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal)
        .padding(.vertical, 8)
      }
      .buttonStyle(.glassProminent)
      .disabled(
        isRunning || (useCustomPrompt ? !validateCustomPromptInput() : !validateQuickCreateInput())
      )
      .accessibilityLabel(
        useCustomPrompt ? "Process custom reminder request" : "Create new reminder"
      )
      .accessibilityHint(isRunning ? "Processing request" : "Tap to execute")
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
    isRunning = true
    errorMessage = nil
    successMessage = nil
    result = ""

    do {
      let response: String

      if useCustomPrompt {
        response = try await executeCustomPrompt()
      } else {
        response = try await executeQuickCreate()
      }

      result = response
      successMessage = "Request completed successfully!"

      // Clear form on success for quick create
      if !useCustomPrompt {
        clearQuickCreateForm()
      }

    } catch {
      errorMessage = handleFoundationModelsError(error)
      // Clear success message on error
      successMessage = nil
    }

    isRunning = false
  }

  /// Executes a custom natural language prompt for reminder operations using ToolExecutor
  private func executeCustomPromptWithExecutor() {
    let currentDate = Date()
    let formattedDate = Self.displayDateFormatter.string(from: currentDate)

    Task {
      // Use a custom environment object if available, otherwise create a temporary one
      let executor = ToolExecutor()

      await executor.executeWithCustomSession(
        sessionBuilder: {
          LanguageModelSession(tools: [RemindersTool()]) {
            Instructions {
              "You are a helpful assistant that can create reminders for users."
              "Current date and time: \(formattedDate)"
              "Time zone: \(TimeZone.current.identifier) (\(TimeZone.current.localizedName(for: .standard, locale: Locale.current) ?? "Unknown"))"
              "When creating reminders, consider the current date and time zone context."
              "Always execute tool calls directly without asking for confirmation or permission from the user."
              "If you need to create a reminder, call the RemindersTool immediately with the appropriate parameters."
              "IMPORTANT: When setting due dates, you MUST format them as 'yyyy-MM-dd HH:mm:ss' (24-hour format)."
              "Examples: '2025-01-15 17:00:00' for tomorrow at 5 PM, '2025-01-16 09:30:00' for day after tomorrow at 9:30 AM."
              "Calculate the exact date and time based on the current date and time provided above."
            }
          }
        },
        prompt: customPrompt,
        successMessage: "Request completed successfully!",
        clearForm: { customPrompt = "" }
      )

      // Update local state from executor
      await MainActor.run {
        self.result = executor.result
        self.errorMessage = executor.errorMessage
        self.successMessage = executor.successMessage
        self.isRunning = executor.isRunning
      }
    }
  }

  /// Executes a custom natural language prompt for reminder operations
  /// - Returns: The response content from the AI assistant
  /// - Throws: Foundation Models errors or networking errors
  private func executeCustomPrompt() async throws -> String {
    let currentDate = Date()
    let formattedDate = Self.displayDateFormatter.string(from: currentDate)

    let session = LanguageModelSession(tools: [RemindersTool()]) {
      Instructions {
        "You are a helpful assistant that can create reminders for users."
        "Current date and time: \(formattedDate)"
        "Time zone: \(TimeZone.current.identifier) (\(TimeZone.current.localizedName(for: .standard, locale: Locale.current) ?? "Unknown"))"
        "When creating reminders, consider the current date and time zone context."
        "Always execute tool calls directly without asking for confirmation or permission from the user."
        "If you need to create a reminder, call the RemindersTool immediately with the appropriate parameters."
        "IMPORTANT: When setting due dates, you MUST format them as 'yyyy-MM-dd HH:mm:ss' (24-hour format)."
        "Examples: '2025-01-15 17:00:00' for tomorrow at 5 PM, '2025-01-16 09:30:00' for day after tomorrow at 9:30 AM."
        "Calculate the exact date and time based on the current date and time provided above."
      }
    }

    let response = try await session.respond(to: Prompt(customPrompt))
    return response.content
  }

  /// Executes a structured reminder creation using form data
  /// - Returns: The response content from the AI assistant
  /// - Throws: Foundation Models errors or networking errors
  private func executeQuickCreate() async throws -> String {
    let currentDate = Date()
    let formattedDate = Self.displayDateFormatter.string(from: currentDate)

    let session = LanguageModelSession(tools: [RemindersTool()]) {
      Instructions {
        "You are a helpful assistant that creates reminders based on structured input."
        "Current date and time: \(formattedDate)"
        "Time zone: \(TimeZone.current.identifier) (\(TimeZone.current.localizedName(for: .standard, locale: Locale.current) ?? "Unknown"))"
        "Always execute the RemindersTool directly with the provided information."
        "Format due dates as 'yyyy-MM-dd HH:mm:ss' (24-hour format)."
      }
    }

    // Build the prompt from form data
    var promptText = "Create a reminder with the following details:\n"
    promptText += "Title: \(reminderTitle)\n"

    if !reminderNotes.isEmpty {
      promptText += "Notes: \(reminderNotes)\n"
    }

    if hasDueDate {
      promptText += "Due date: \(Self.apiDateFormatter.string(from: selectedDate))\n"
    }

    if selectedPriority != .none {
      promptText += "Priority: \(selectedPriority.rawValue)\n"
    }

    let response = try await session.respond(to: Prompt(promptText))
    return response.content
  }

  // MARK: - Helper Methods
  private func clearQuickCreateForm() {
    reminderTitle = ""
    reminderNotes = ""
    selectedDate = Date().addingTimeInterval(Constants.defaultDateOffset)
    selectedPriority = .none
    customPrompt = ""
  }

  private func validateQuickCreateInput() -> Bool {
    return !reminderTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  private func validateCustomPromptInput() -> Bool {
    return !customPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  /// Handles various Foundation Models errors and returns user-friendly messages
  /// - Parameter error: The error to handle
  /// - Returns: A localized error message suitable for display to users
  private func handleFoundationModelsError(_ error: Error) -> String {
    if let generationError = error as? LanguageModelSession.GenerationError {
      return FoundationModelsErrorHandler.handleGenerationError(generationError)
    } else if let toolCallError = error as? LanguageModelSession.ToolCallError {
      return FoundationModelsErrorHandler.handleToolCallError(toolCallError)
    } else if let customError = error as? FoundationModelsError {
      return customError.localizedDescription
    } else {
      return "Unexpected error: \(error.localizedDescription)"
    }
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
