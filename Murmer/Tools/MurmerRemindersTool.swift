//
//  MurmerRemindersTool.swift
//  Murmer
//
//  Created by Rudrank Riyam on 6/26/25.
//

@preconcurrency import EventKit
import Foundation
import FoundationModels

/// AI-powered reminder creation tool for Murmer

struct MurmerRemindersTool: Tool {
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

  func call(arguments: Arguments) async throws -> some PromptRepresentable {
    let eventStore = EKEventStore()
    
    // Check and request permissions
    let authStatus = EKEventStore.authorizationStatus(for: .reminder)
    if !Self.isRemindersAccessGranted(authStatus) {
      let authorized = await requestAccess(eventStore)
      guard authorized else {
        throw MurmerError.accessDenied
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
        throw MurmerError.noDefaultList
      }
      calendar = defaultCalendar
    }

    reminder.calendar = calendar

    // Save the reminder
    try await withCheckedThrowingContinuation { continuation in
      DispatchQueue.main.async {
        do {
          try eventStore.save(reminder, commit: true)
          continuation.resume()
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }

    let successMessage = arguments.dueDate != nil 
      ? "Reminder '\(reminder.title ?? "")' created successfully with due date."
      : "Reminder '\(reminder.title ?? "")' created successfully."
    
    return successMessage
  }




  private func requestAccess(_ eventStore: EKEventStore) async -> Bool {
    do {
      if #available(macOS 14.0, iOS 17.0, *) {
        let result = try await eventStore.requestFullAccessToReminders()
        if result {
          return true
        }
        // Fallback to legacy API if full access is unavailable (e.g. entitlement missing)
      } else {
        let result = try await eventStore.requestAccess(to: .reminder)
        return result
      }
      let result = try await eventStore.requestAccess(to: .reminder)
      return result
    } catch {
      return false
    }
  }

  private static func isRemindersAccessGranted(_ status: EKAuthorizationStatus) -> Bool {
    if #available(iOS 17.0, macOS 14.0, *) {
      return status == .fullAccess || status == .authorized
    } else {
      return status == .authorized
    }
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
      throw MurmerError.cannotCreateList
    }

    try await withCheckedThrowingContinuation { continuation in
      DispatchQueue.main.async {
        do {
          try eventStore.saveCalendar(newCalendar, commit: true)
          continuation.resume()
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
    return newCalendar
  }
}



// MARK: - Errors
enum MurmerError: LocalizedError {
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
