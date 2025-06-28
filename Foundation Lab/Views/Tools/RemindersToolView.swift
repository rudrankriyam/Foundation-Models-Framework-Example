//
//  RemindersToolView.swift
//  FoundationLab
//
//  Created by Claude on 1/14/25.
//

import FoundationModels
import SwiftUI

struct RemindersToolView: View {
  @State private var isRunning = false
  @State private var result: String = ""
  @State private var errorMessage: String?
  @State private var successMessage: String?

  // Input fields
  @State private var reminderTitle: String = ""
  @State private var reminderNotes: String = ""
  @State private var selectedDate = Date().addingTimeInterval(3600)  // 1 hour from now
  @State private var hasDueDate = true
  @State private var selectedPriority: ReminderPriority = .none
  @State private var customPrompt: String = ""
  @State private var useCustomPrompt = false

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
          } else {
            Image(systemName: useCustomPrompt ? "bubble.left.and.bubble.right" : "plus")
          }

          Text(useCustomPrompt ? "Process Request" : "Create Reminder")
            .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal)
        .padding(.vertical, 8)
      }
      .buttonStyle(.glassProminent)
      .disabled(isRunning || (useCustomPrompt ? customPrompt.isEmpty : reminderTitle.isEmpty))
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
      .lineLimit(3...6)
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
          .lineLimit(2...4)
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
    }

    isRunning = false
  }

  private func executeCustomPrompt() async throws -> String {
    let currentDate = Date()
    let formatter = DateFormatter()
    formatter.dateStyle = .full
    formatter.timeStyle = .short

    let session = LanguageModelSession(tools: [RemindersTool()]) {
      Instructions {
        "You are a helpful assistant that can create reminders for users."
        "Current date and time: \(formatter.string(from: currentDate))"
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

  private func executeQuickCreate() async throws -> String {
    let currentDate = Date()
    let formatter = DateFormatter()
    formatter.dateStyle = .full
    formatter.timeStyle = .short

    let session = LanguageModelSession(tools: [RemindersTool()]) {
      Instructions {
        "You are a helpful assistant that creates reminders based on structured input."
        "Current date and time: \(formatter.string(from: currentDate))"
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
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
      promptText += "Due date: \(dateFormatter.string(from: selectedDate))\n"
    }

    if selectedPriority != .none {
      promptText += "Priority: \(selectedPriority.rawValue)\n"
    }

    let response = try await session.respond(to: Prompt(promptText))
    return response.content
  }

  private func clearQuickCreateForm() {
    reminderTitle = ""
    reminderNotes = ""
    selectedDate = Date().addingTimeInterval(3600)
    selectedPriority = .none
  }

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

enum ReminderPriority: String, CaseIterable {
  case none = "none"
  case low = "low"
  case medium = "medium"
  case high = "high"

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
