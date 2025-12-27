//
//  RemindersToolViewHelpers.swift
//  Foundation Lab
//
//  Created by Rudrank Riyam on 10/27/25.
//

import Foundation
import FoundationModels
import FoundationModelsTools
import SwiftUI

extension RemindersToolView {
    struct ExecutionConfig {
        let useCustomPrompt: Bool
        let customPrompt: String
        let reminderTitle: String
        let reminderNotes: String
        let hasDueDate: Bool
        let selectedDate: Date
        let selectedPriority: ReminderPriority
    }

    func createCustomPromptInstructions(formattedDate: String) -> Instructions {
        Instructions {
            "You are a helpful assistant that can create reminders for users."
            "Current date and time: \(formattedDate)"
            "Time zone: \(TimeZone.current.identifier) (" +
            "\(TimeZone.current.localizedName(for: .standard, locale: Locale.current) ?? "Unknown"))"
            "When creating reminders, consider the current date and time zone context."
            "Always execute tool calls directly without asking for confirmation or permission from the user."
            "If you need to create a reminder, call the RemindersTool immediately with the appropriate parameters."
            "IMPORTANT: When setting due dates, you MUST format them as 'yyyy-MM-dd HH:mm:ss' " +
            "(24-hour format)."
            "Examples: '2025-01-15 17:00:00' for tomorrow at 5 PM, '2025-01-16 09:30:00' for " +
            "day after tomorrow at 9:30 AM."
            "Calculate the exact date and time based on the current date and time provided above."
        }
    }

    func createQuickCreateInstructions(formattedDate: String) -> Instructions {
        Instructions {
            "You are a helpful assistant that creates reminders based on structured input."
            "Current date and time: \(formattedDate)"
            "Time zone: \(TimeZone.current.identifier) (" +
            "\(TimeZone.current.localizedName(for: .standard, locale: Locale.current) ?? "Unknown"))"
            "Always execute the RemindersTool directly with the provided information."
            "Format due dates as 'yyyy-MM-dd HH:mm:ss' (24-hour format)."
        }
    }

    func executeCustomPrompt(config: ExecutionConfig) async throws -> String {
        let currentDate = Date()
        let formattedDate = Self.displayDateFormatter.string(from: currentDate)

        let session = LanguageModelSession(tools: [RemindersTool()]) {
            createCustomPromptInstructions(formattedDate: formattedDate)
        }

        let response = try await session.respond(to: Prompt(config.customPrompt))
        return response.content
    }

    func executeQuickCreate(config: ExecutionConfig) async throws -> String {
        let currentDate = Date()
        let formattedDate = Self.displayDateFormatter.string(from: currentDate)

        let session = LanguageModelSession(tools: [RemindersTool()]) {
            createQuickCreateInstructions(formattedDate: formattedDate)
        }

        // Build the prompt from form data
        var promptText = "Create a reminder with the following details:\n"
        promptText += "Title: \(config.reminderTitle)\n"

        if !config.reminderNotes.isEmpty {
            promptText += "Notes: \(config.reminderNotes)\n"
        }

        if config.hasDueDate {
            promptText += "Due date: \(Self.apiDateFormatter.string(from: config.selectedDate))\n"
        }

        if config.selectedPriority != .none {
            promptText += "Priority: \(config.selectedPriority.rawValue)\n"
        }

        let response = try await session.respond(to: Prompt(promptText))
        return response.content
    }

    func validateQuickCreateInput(reminderTitle: String) -> Bool {
        return !reminderTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func validateCustomPromptInput(customPrompt: String) -> Bool {
        return !customPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @ViewBuilder
    func actionButtonView(
        useCustomPrompt: Bool,
        isRunning: Bool,
        action: @escaping () -> Void,
        isDisabled: Bool
    ) -> some View {
        Button(action: action) {
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
        .disabled(isDisabled)
        .accessibilityLabel(
            useCustomPrompt ? "Process custom reminder request" : "Create new reminder"
        )
        .accessibilityHint(isRunning ? "Processing request" : "Tap to execute")
    }
}
