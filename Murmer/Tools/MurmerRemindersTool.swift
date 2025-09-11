//
//  MurmerRemindersTool.swift
//  Murmer
//
//  Created by Rudrank Riyam on 6/26/25.
//

@preconcurrency import EventKit
import Foundation
import FoundationModels

struct MurmerRemindersTool: Tool {
  let name = "createReminder"
  let description = "Create a reminder from voice input"

  @Generable
  struct Arguments {
    @Guide(description: "The reminder text from voice input")
    var text: String

    @Guide(
      description:
        "Optional due date/time parsed from speech (e.g., 'tomorrow at 3pm', 'in 2 hours')")
    var timeExpression: String?

    @Guide(description: "The reminder list name (defaults to default list)")
    var listName: String?
  }

  private let eventStore = EKEventStore()

  func call(arguments: Arguments) async throws -> some PromptRepresentable {
    // Check EventStore permissions
    let authStatus = EKEventStore.authorizationStatus(for: .reminder)

    // Request access if needed
    if authStatus != .fullAccess {
      let authorized = await requestAccess()

      guard authorized else {
        throw MurmerError.accessDenied
      }
    }

    // Create reminder
    let reminder = EKReminder(eventStore: eventStore)
    reminder.title = arguments.text

    // Parse time expression if provided
    if let timeExpression = arguments.timeExpression {
      if let dueDate = parseTimeExpression(timeExpression) {
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
      do {
        calendar = try await getOrCreateList(named: listName)
      } catch {
        throw error
      }
    } else {
      guard let defaultCalendar = eventStore.defaultCalendarForNewReminders() else {
        throw MurmerError.noDefaultList
      }
      calendar = defaultCalendar
    }

    reminder.calendar = calendar

    // Save the reminder
    do {
      try eventStore.save(reminder, commit: true)
    } catch {
      throw error
    }

    let output = ReminderOutput(
      id: reminder.calendarItemIdentifier,
      title: reminder.title ?? "",
      dueDate: reminder.dueDateComponents?.date,
      listName: calendar.title,
      success: true,
      message: "Reminder created successfully"
    )


      return await output.generatedContent
  }

  private func requestAccess() async -> Bool {
    do {
      if #available(macOS 14.0, iOS 17.0, *) {
        let result = try await eventStore.requestFullAccessToReminders()
        return result
      } else {
        let result = try await eventStore.requestAccess(to: .reminder)
        return result
      }
    } catch {
      return false
    }
  }

  private func parseTimeExpression(_ expression: String) -> Date? {
    let lowercased = expression.lowercased()
    let now = Date()
    let calendar = Calendar.current

    // Handle relative time expressions
    if lowercased.contains("tomorrow") {
      var components = DateComponents(day: 1)

      // Extract time if specified
      if let time = extractTime(from: lowercased) {
        components.hour = time.hour
        components.minute = time.minute
      }

      let startOfDay = calendar.startOfDay(for: now)
      let result = calendar.date(byAdding: components, to: startOfDay)
      return result
    }

    if lowercased.contains("today") {
      var date = now

      // Extract time if specified
      if let time = extractTime(from: lowercased) {
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = time.hour
        components.minute = time.minute
        date = calendar.date(from: components) ?? now
      }

      return date
    }

    // Handle "in X hours/minutes"
    if lowercased.contains("in ") {

      if let hours = extractNumber(from: lowercased, unit: "hour") {
        let result = calendar.date(byAdding: .hour, value: hours, to: now)
          "[MurmerRemindersTool.parseTimeExpression] Date in \(hours) hours: \(result?.description ?? "nil")"
        )
        return result
      }
      if let minutes = extractNumber(from: lowercased, unit: "minute") {
        let result = calendar.date(byAdding: .minute, value: minutes, to: now)
          "[MurmerRemindersTool.parseTimeExpression] Date in \(minutes) minutes: \(result?.description ?? "nil")"
        )
        return result
      }
      if let days = extractNumber(from: lowercased, unit: "day") {
        let result = calendar.date(byAdding: .day, value: days, to: now)
          "[MurmerRemindersTool.parseTimeExpression] Date in \(days) days: \(result?.description ?? "nil")"
        )
        return result
      }
    }

    // Handle next week
    if lowercased.contains("next week") {
      let result = calendar.date(byAdding: .weekOfYear, value: 1, to: now)
        "[MurmerRemindersTool.parseTimeExpression] Next week date: \(result?.description ?? "nil")")
      return result
    }

    // Handle day names
    let dayNames = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
    for (index, dayName) in dayNames.enumerated() {
      if lowercased.contains(dayName) {
        let weekday = index + 1  // Sunday = 1
        let result = nextOccurrence(of: weekday, from: now)
          "[MurmerRemindersTool.parseTimeExpression] Next \(dayName) date: \(result?.description ?? "nil")"
        )
        return result
      }
    }

    return nil
  }

  private func extractTime(from text: String) -> (hour: Int, minute: Int)? {
    // Match patterns like "3pm", "3:30pm", "15:30" - simplified to single pattern
    let pattern = #"(\d{1,2})(:(\d{2}))?\s*(am|pm)?"#

    do {
      let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
      let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))

      if let match = matches.first {
          "[MurmerRemindersTool.extractTime] Processing first match with \(match.numberOfRanges) ranges"
        )
        if match.numberOfRanges >= 2,
          let hourRange = Range(match.range(at: 1), in: text),
          let hour = Int(text[hourRange])
        {

          var finalHour = hour
          var minute = 0

          // Extract minutes if present (group 3, since group 2 is the full ":mm" part)
          if match.numberOfRanges >= 4,
            let minuteRange = Range(match.range(at: 3), in: text)
          {
            minute = Int(text[minuteRange]) ?? 0
          }

          // Handle AM/PM (group 4)
          if match.numberOfRanges >= 5,
            let amPmRange = Range(match.range(at: 4), in: text)
          {
            let amPm = text[amPmRange].lowercased()
            if amPm == "pm" && finalHour < 12 {
              finalHour += 12
            } else if amPm == "am" && finalHour == 12 {
              finalHour = 0
            }
          }

          return (finalHour, minute)
        }
      }
    } catch {
        "[MurmerRemindersTool.extractTime] ERROR: Failed to create regex for pattern \(pattern): \(error)"
      )
    }

    return nil
  }

  private func extractNumber(from text: String, unit: String) -> Int? {
      "[MurmerRemindersTool.extractNumber] Looking for number with unit '\(unit)' in: '\(text)'")
    let pattern = #"(\d+)\s*"# + unit

    do {
      let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
      let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))

      if let match = matches.first,
        let numberRange = Range(match.range(at: 1), in: text),
        let number = Int(text[numberRange])
      {
        return number
      }
    } catch {
    }

    // Handle written numbers
    let writtenNumbers = [
      "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
      "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
    ]

    for (written, value) in writtenNumbers {
      if text.contains("\(written) \(unit)") {
        return value
      }
    }

    return nil
  }

  private func nextOccurrence(of weekday: Int, from date: Date) -> Date? {
      "[MurmerRemindersTool.nextOccurrence] Finding next occurrence of weekday \(weekday) from \(date)"
    )
    let calendar = Calendar.current
    let currentWeekday = calendar.component(.weekday, from: date)

    var daysToAdd = weekday - currentWeekday
    if daysToAdd <= 0 {
      daysToAdd += 7
    }

    let result = calendar.date(byAdding: .day, value: daysToAdd, to: date)
    return result
  }

  private func getOrCreateList(named name: String) async throws -> EKCalendar {

    // Check if list exists
    let calendars = eventStore.calendars(for: .reminder)

    for (index, cal) in calendars.enumerated() {
        "[MurmerRemindersTool.getOrCreateList]   Calendar \(index): '\(cal.title)' (ID: \(cal.calendarIdentifier))"
      )
    }

    if let existingCalendar = calendars.first(where: { $0.title.lowercased() == name.lowercased() })
    {
        "[MurmerRemindersTool.getOrCreateList] Found existing calendar: '\(existingCalendar.title)'"
      )
      return existingCalendar
    }


    // Create new list
    let newCalendar = EKCalendar(for: .reminder, eventStore: eventStore)
    newCalendar.title = name

    let defaultCalendar = eventStore.defaultCalendarForNewReminders()
      "[MurmerRemindersTool.getOrCreateList] Default calendar: \(defaultCalendar?.title ?? "nil")")

    newCalendar.source = defaultCalendar?.source
      "[MurmerRemindersTool.getOrCreateList] Calendar source: \(newCalendar.source?.title ?? "nil")"
    )

    guard newCalendar.source != nil else {
      throw MurmerError.cannotCreateList
    }

    do {
      try eventStore.saveCalendar(newCalendar, commit: true)
        "[MurmerRemindersTool.getOrCreateList] Successfully saved new calendar: '\(newCalendar.title)'"
      )
    } catch {
      throw error
    }

    return newCalendar
  }
}

// MARK: - Output Types
struct ReminderOutput: ConvertibleToGeneratedContent {
  let id: String
  let title: String
  let dueDate: Date?
  let listName: String
  let success: Bool
  let message: String

  var generatedContent: GeneratedContent {
    GeneratedContent(properties: [
      "id": id,
      "title": title,
      "dueDate": dueDate?.description ?? "",
      "listName": listName,
      "success": success,
      "message": message,
    ])
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
