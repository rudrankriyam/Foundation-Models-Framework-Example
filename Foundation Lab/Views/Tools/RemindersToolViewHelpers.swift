//
//  RemindersToolViewHelpers.swift
//  Foundation Lab
//
//  Created by Rudrank Riyam on 10/27/25.
//

import Foundation
import FoundationLabCore
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

    func makeRequest(from config: ExecutionConfig) -> ManageRemindersRequest {
        ManageRemindersRequest(
            mode: config.useCustomPrompt ? .customPrompt : .quickCreate,
            customPrompt: config.useCustomPrompt ? config.customPrompt : nil,
            title: config.useCustomPrompt ? nil : config.reminderTitle,
            notes: config.useCustomPrompt ? nil : config.reminderNotes,
            dueDate: config.useCustomPrompt ? nil : (config.hasDueDate ? config.selectedDate : nil),
            priority: config.useCustomPrompt ? .none : config.selectedPriority.corePriority,
            referenceDate: .now,
            timeZoneIdentifier: TimeZone.current.identifier,
            context: CapabilityInvocationContext(
                source: .app,
                localeIdentifier: Locale.current.identifier
            )
        )
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

private extension ReminderPriority {
    var corePriority: ReminderPriorityValue {
        switch self {
        case .none:
            return .none
        case .low:
            return .low
        case .medium:
            return .medium
        case .high:
            return .high
        }
    }
}
