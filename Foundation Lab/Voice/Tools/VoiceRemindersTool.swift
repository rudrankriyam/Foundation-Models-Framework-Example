//
//  VoiceRemindersTool.swift
//  Foundation Lab
//
//  Created by Rudrank Riyam on 10/27/25.
//

@preconcurrency import EventKit
import Foundation
import FoundationModels

// MARK: - Voice Reminders Tool

/// AI-powered reminder creation tool for Voice functionality

struct VoiceRemindersTool: Tool {
    let name = "createReminder"
    let description = "Create a reminder from voice input"

    @Generable
    struct Arguments {
        @Guide(description: "The reminder text/title")
        var text: String

        @Guide(description: "The due date for the reminder in ISO8601 format (optional)")
        var dueDate: String?

        @Guide(description: "The reminder list name (defaults to default list)")
        var listName: String?
    }

    @MainActor
    func call(arguments: Arguments) async throws -> some PromptRepresentable {
        let eventStore = EKEventStore()

        // Check and request permissions
        let authStatus = EKEventStore.authorizationStatus(for: .reminder)
        if !Self.isRemindersAccessGranted(authStatus) {
            let authorized = await requestAccess(eventStore)
            guard authorized else {
                throw VoiceReminderError.accessDenied
            }
        }

        // Create reminder
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = arguments.text

        // Set due date if provided by the AI
        if let dueDateString = arguments.dueDate {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withTimeZone]
            if let dueDate = formatter.date(from: dueDateString) {
                let components = Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: dueDate
                )
                reminder.dueDateComponents = components

                // Add alarm for the due date
                let alarm = EKAlarm(absoluteDate: dueDate)
                reminder.addAlarm(alarm)
            }
        }

        // Get the appropriate calendar
        let calendar: EKCalendar
        if let listName = arguments.listName {
            calendar = try await getOrCreateList(named: listName, eventStore: eventStore)
        } else {
            guard let defaultCalendar = eventStore.defaultCalendarForNewReminders() else {
                throw VoiceReminderError.noDefaultList
            }
            calendar = defaultCalendar
        }

        reminder.calendar = calendar

        // Save the reminder
        try eventStore.save(reminder, commit: true)

        let successMessage = arguments.dueDate != nil
            ? "Reminder '\(reminder.title ?? "")' created successfully with due date."
            : "Reminder '\(reminder.title ?? "")' created successfully."

        return successMessage
    }

    private func requestAccess(_ eventStore: EKEventStore) async -> Bool {
        do {
            let result = try await eventStore.requestFullAccessToReminders()
            return result
        } catch {
            return false
        }
    }

    private static func isRemindersAccessGranted(_ status: EKAuthorizationStatus) -> Bool {
        status == .fullAccess || status == .writeOnly
    }

    private func getOrCreateList(named name: String, eventStore: EKEventStore) async throws -> EKCalendar {
        // Check if list exists
        let calendars = eventStore.calendars(for: .reminder)

        if let existingCalendar = calendars.first(where: { $0.title.lowercased() == name.lowercased() }) {
            return existingCalendar
        }

        // Create new list
        let newCalendar = EKCalendar(for: .reminder, eventStore: eventStore)
        newCalendar.title = name

        let defaultCalendar = eventStore.defaultCalendarForNewReminders()
        newCalendar.source = defaultCalendar?.source

        guard newCalendar.source != nil else {
            throw VoiceReminderError.cannotCreateList
        }

        try eventStore.saveCalendar(newCalendar, commit: true)
        return newCalendar
    }
}

// MARK: - Errors

enum VoiceReminderError: LocalizedError {
    case noDefaultList
    case cannotCreateList
    case accessDenied

    var errorDescription: String? {
        switch self {
        case .noDefaultList:
            return "No default reminders list found"
        case .cannotCreateList:
            return "Cannot create new reminders list"
        case .accessDenied:
            return "Access to reminders was denied"
        }
    }
}