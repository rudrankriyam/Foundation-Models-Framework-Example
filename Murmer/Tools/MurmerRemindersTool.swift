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
    print("[MurmerRemindersTool] ===== TOOL CALL START =====")
    print("[MurmerRemindersTool] Arguments received:")
    print("[MurmerRemindersTool]   - text: '\(arguments.text)'")
    print("[MurmerRemindersTool]   - timeExpression: \(arguments.timeExpression ?? "nil")")
    print("[MurmerRemindersTool]   - listName: \(arguments.listName ?? "nil")")
    print("[MurmerRemindersTool] Current date/time: \(Date())")

    // Check EventStore permissions
    print("[MurmerRemindersTool] Checking EventStore authorization status...")
    let authStatus = EKEventStore.authorizationStatus(for: .reminder)
    print("[MurmerRemindersTool] Authorization status: \(authStatus.rawValue)")

    // Request access if needed
    if authStatus != .fullAccess {
      print("[MurmerRemindersTool] Requesting reminder access...")
      let authorized = await requestAccess()
      print("[MurmerRemindersTool] Access request result: \(authorized)")

      guard authorized else {
        print("[MurmerRemindersTool] ERROR: Access denied!")
        throw MurmerError.accessDenied
      }
    } else {
      print("[MurmerRemindersTool] Already have access to reminders")
    }

    // Create reminder
    print("[MurmerRemindersTool] Creating EKReminder object...")
    let reminder = EKReminder(eventStore: eventStore)
    reminder.title = arguments.text
    print("[MurmerRemindersTool] Reminder created with title: '\(reminder.title ?? "nil")'")

    // Parse time expression if provided
    if let timeExpression = arguments.timeExpression {
      print("[MurmerRemindersTool] Time expression provided: '\(timeExpression)'")
      print("[MurmerRemindersTool] Attempting to parse time expression...")

      if let dueDate = parseTimeExpression(timeExpression) {
        print("[MurmerRemindersTool] Successfully parsed due date: \(dueDate)")

        let components = Calendar.current.dateComponents(
          [.year, .month, .day, .hour, .minute],
          from: dueDate
        )
        reminder.dueDateComponents = components
        print(
          "[MurmerRemindersTool] Set due date components: year=\(components.year ?? -1), month=\(components.month ?? -1), day=\(components.day ?? -1), hour=\(components.hour ?? -1), minute=\(components.minute ?? -1)"
        )

        // Add alarm for the due date
        print("[MurmerRemindersTool] Creating alarm for due date...")
        let alarm = EKAlarm(absoluteDate: dueDate)
        reminder.addAlarm(alarm)
        print("[MurmerRemindersTool] Alarm added successfully")
      } else {
        print("[MurmerRemindersTool] WARNING: Failed to parse time expression '\(timeExpression)'")
      }
    } else {
      print("[MurmerRemindersTool] No time expression provided")
    }

    // Get the appropriate calendar
    print("[MurmerRemindersTool] Getting appropriate calendar...")
    let calendar: EKCalendar
    if let listName = arguments.listName {
      print("[MurmerRemindersTool] Custom list requested: '\(listName)'")
      do {
        calendar = try await getOrCreateList(named: listName)
        print("[MurmerRemindersTool] Successfully got/created calendar: '\(calendar.title)'")
      } catch {
        print(
          "[MurmerRemindersTool] ERROR: Failed to get/create list: \(error.localizedDescription)")
        throw error
      }
    } else {
      print("[MurmerRemindersTool] No custom list specified, getting default calendar...")
      guard let defaultCalendar = eventStore.defaultCalendarForNewReminders() else {
        print("[MurmerRemindersTool] ERROR: No default calendar found!")
        throw MurmerError.noDefaultList
      }
      calendar = defaultCalendar
      print("[MurmerRemindersTool] Using default calendar: '\(calendar.title)'")
    }

    reminder.calendar = calendar
    print("[MurmerRemindersTool] Calendar set for reminder")

    // Save the reminder
    print("[MurmerRemindersTool] Attempting to save reminder...")
    do {
      try eventStore.save(reminder, commit: true)
      print("[MurmerRemindersTool] SUCCESS: Reminder saved successfully!")
      print("[MurmerRemindersTool] Reminder ID: \(reminder.calendarItemIdentifier)")
    } catch {
      print("[MurmerRemindersTool] ERROR: Failed to save reminder: \(error)")
      print("[MurmerRemindersTool] Error type: \(type(of: error))")
      print("[MurmerRemindersTool] Error localized description: \(error.localizedDescription)")
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

    print("[MurmerRemindersTool] Creating output...")
    print("[MurmerRemindersTool] Output details:")
    print("[MurmerRemindersTool]   - id: \(output.id)")
    print("[MurmerRemindersTool]   - title: \(output.title)")
    print("[MurmerRemindersTool]   - dueDate: \(output.dueDate?.description ?? "nil")")
    print("[MurmerRemindersTool]   - listName: \(output.listName)")
    print("[MurmerRemindersTool] ===== TOOL CALL END =====")

      return await output.generatedContent
  }

  private func requestAccess() async -> Bool {
    print("[MurmerRemindersTool.requestAccess] Requesting access to reminders...")
    do {
      if #available(macOS 14.0, iOS 17.0, *) {
        print("[MurmerRemindersTool.requestAccess] Using requestFullAccessToReminders (iOS 17+)")
        let result = try await eventStore.requestFullAccessToReminders()
        print("[MurmerRemindersTool.requestAccess] Access result: \(result)")
        return result
      } else {
        print("[MurmerRemindersTool.requestAccess] Using legacy requestAccess")
        let result = try await eventStore.requestAccess(to: .reminder)
        print("[MurmerRemindersTool.requestAccess] Access result: \(result)")
        return result
      }
    } catch {
      print("[MurmerRemindersTool.requestAccess] ERROR: Failed to request access: \(error)")
      return false
    }
  }

  private func parseTimeExpression(_ expression: String) -> Date? {
    print("[MurmerRemindersTool.parseTimeExpression] Parsing expression: '\(expression)'")
    let lowercased = expression.lowercased()
    print("[MurmerRemindersTool.parseTimeExpression] Lowercased: '\(lowercased)'")
    let now = Date()
    print("[MurmerRemindersTool.parseTimeExpression] Current time: \(now)")
    let calendar = Calendar.current

    // Handle relative time expressions
    if lowercased.contains("tomorrow") {
      print("[MurmerRemindersTool.parseTimeExpression] Found 'tomorrow' in expression")
      var components = DateComponents(day: 1)

      // Extract time if specified
      if let time = extractTime(from: lowercased) {
        print(
          "[MurmerRemindersTool.parseTimeExpression] Extracted time: \(time.hour):\(time.minute)")
        components.hour = time.hour
        components.minute = time.minute
      } else {
        print("[MurmerRemindersTool.parseTimeExpression] No specific time found for tomorrow")
      }

      let startOfDay = calendar.startOfDay(for: now)
      let result = calendar.date(byAdding: components, to: startOfDay)
      print(
        "[MurmerRemindersTool.parseTimeExpression] Tomorrow date calculated: \(result?.description ?? "nil")"
      )
      return result
    }

    if lowercased.contains("today") {
      print("[MurmerRemindersTool.parseTimeExpression] Found 'today' in expression")
      var date = now

      // Extract time if specified
      if let time = extractTime(from: lowercased) {
        print(
          "[MurmerRemindersTool.parseTimeExpression] Extracted time: \(time.hour):\(time.minute)")
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = time.hour
        components.minute = time.minute
        date = calendar.date(from: components) ?? now
        print("[MurmerRemindersTool.parseTimeExpression] Today with time: \(date)")
      } else {
        print("[MurmerRemindersTool.parseTimeExpression] No specific time found for today")
      }

      return date
    }

    // Handle "in X hours/minutes"
    if lowercased.contains("in ") {
      print("[MurmerRemindersTool.parseTimeExpression] Found 'in' pattern")

      if let hours = extractNumber(from: lowercased, unit: "hour") {
        print("[MurmerRemindersTool.parseTimeExpression] Extracted hours: \(hours)")
        let result = calendar.date(byAdding: .hour, value: hours, to: now)
        print(
          "[MurmerRemindersTool.parseTimeExpression] Date in \(hours) hours: \(result?.description ?? "nil")"
        )
        return result
      }
      if let minutes = extractNumber(from: lowercased, unit: "minute") {
        print("[MurmerRemindersTool.parseTimeExpression] Extracted minutes: \(minutes)")
        let result = calendar.date(byAdding: .minute, value: minutes, to: now)
        print(
          "[MurmerRemindersTool.parseTimeExpression] Date in \(minutes) minutes: \(result?.description ?? "nil")"
        )
        return result
      }
      if let days = extractNumber(from: lowercased, unit: "day") {
        print("[MurmerRemindersTool.parseTimeExpression] Extracted days: \(days)")
        let result = calendar.date(byAdding: .day, value: days, to: now)
        print(
          "[MurmerRemindersTool.parseTimeExpression] Date in \(days) days: \(result?.description ?? "nil")"
        )
        return result
      }
      print("[MurmerRemindersTool.parseTimeExpression] 'in' pattern found but no number extracted")
    }

    // Handle next week
    if lowercased.contains("next week") {
      print("[MurmerRemindersTool.parseTimeExpression] Found 'next week' in expression")
      let result = calendar.date(byAdding: .weekOfYear, value: 1, to: now)
      print(
        "[MurmerRemindersTool.parseTimeExpression] Next week date: \(result?.description ?? "nil")")
      return result
    }

    // Handle day names
    let dayNames = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
    print("[MurmerRemindersTool.parseTimeExpression] Checking for day names...")
    for (index, dayName) in dayNames.enumerated() {
      if lowercased.contains(dayName) {
        print("[MurmerRemindersTool.parseTimeExpression] Found day name: '\(dayName)'")
        let weekday = index + 1  // Sunday = 1
        let result = nextOccurrence(of: weekday, from: now)
        print(
          "[MurmerRemindersTool.parseTimeExpression] Next \(dayName) date: \(result?.description ?? "nil")"
        )
        return result
      }
    }

    print("[MurmerRemindersTool.parseTimeExpression] No matching pattern found, returning nil")
    return nil
  }

  private func extractTime(from text: String) -> (hour: Int, minute: Int)? {
    print("[MurmerRemindersTool.extractTime] Extracting time from: '\(text)'")
    // Match patterns like "3pm", "3:30pm", "15:30" - simplified to single pattern
    let pattern = #"(\d{1,2})(:(\d{2}))?\s*(am|pm)?"#
    print("[MurmerRemindersTool.extractTime] Using simplified pattern: \(pattern)")

    do {
      let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
      let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
      print("[MurmerRemindersTool.extractTime] Found \(matches.count) matches")

      if let match = matches.first {
        print(
          "[MurmerRemindersTool.extractTime] Processing first match with \(match.numberOfRanges) ranges"
        )
        if match.numberOfRanges >= 2,
          let hourRange = Range(match.range(at: 1), in: text),
          let hour = Int(text[hourRange])
        {

          print("[MurmerRemindersTool.extractTime] Extracted hour: \(hour)")
          var finalHour = hour
          var minute = 0

          // Extract minutes if present (group 3, since group 2 is the full ":mm" part)
          if match.numberOfRanges >= 4,
            let minuteRange = Range(match.range(at: 3), in: text)
          {
            minute = Int(text[minuteRange]) ?? 0
            print("[MurmerRemindersTool.extractTime] Extracted minute: \(minute)")
          }

          // Handle AM/PM (group 4)
          if match.numberOfRanges >= 5,
            let amPmRange = Range(match.range(at: 4), in: text)
          {
            let amPm = text[amPmRange].lowercased()
            print("[MurmerRemindersTool.extractTime] Found AM/PM: '\(amPm)'")
            if amPm == "pm" && finalHour < 12 {
              finalHour += 12
              print("[MurmerRemindersTool.extractTime] Adjusted hour for PM: \(finalHour)")
            } else if amPm == "am" && finalHour == 12 {
              finalHour = 0
              print("[MurmerRemindersTool.extractTime] Adjusted hour for 12 AM: \(finalHour)")
            }
          }

          print("[MurmerRemindersTool.extractTime] Extracted time: \(finalHour):\(minute)")
          return (finalHour, minute)
        }
      }
    } catch {
      print(
        "[MurmerRemindersTool.extractTime] ERROR: Failed to create regex for pattern \(pattern): \(error)"
      )
    }

    print("[MurmerRemindersTool.extractTime] No time pattern matched")
    return nil
  }

  private func extractNumber(from text: String, unit: String) -> Int? {
    print(
      "[MurmerRemindersTool.extractNumber] Looking for number with unit '\(unit)' in: '\(text)'")
    let pattern = #"(\d+)\s*"# + unit
    print("[MurmerRemindersTool.extractNumber] Using pattern: \(pattern)")

    do {
      let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
      let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))

      if let match = matches.first,
        let numberRange = Range(match.range(at: 1), in: text),
        let number = Int(text[numberRange])
      {
        print("[MurmerRemindersTool.extractNumber] Found number: \(number)")
        return number
      }
    } catch {
      print("[MurmerRemindersTool.extractNumber] ERROR: Failed to create regex: \(error)")
    }

    // Handle written numbers
    let writtenNumbers = [
      "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
      "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
    ]

    for (written, value) in writtenNumbers {
      if text.contains("\(written) \(unit)") {
        print("[MurmerRemindersTool.extractNumber] Found written number '\(written)': \(value)")
        return value
      }
    }

    print("[MurmerRemindersTool.extractNumber] No number found")
    return nil
  }

  private func nextOccurrence(of weekday: Int, from date: Date) -> Date? {
    print(
      "[MurmerRemindersTool.nextOccurrence] Finding next occurrence of weekday \(weekday) from \(date)"
    )
    let calendar = Calendar.current
    let currentWeekday = calendar.component(.weekday, from: date)
    print("[MurmerRemindersTool.nextOccurrence] Current weekday: \(currentWeekday)")

    var daysToAdd = weekday - currentWeekday
    if daysToAdd <= 0 {
      daysToAdd += 7
    }
    print("[MurmerRemindersTool.nextOccurrence] Days to add: \(daysToAdd)")

    let result = calendar.date(byAdding: .day, value: daysToAdd, to: date)
    print("[MurmerRemindersTool.nextOccurrence] Result date: \(result?.description ?? "nil")")
    return result
  }

  private func getOrCreateList(named name: String) async throws -> EKCalendar {
    print("[MurmerRemindersTool.getOrCreateList] Looking for list named: '\(name)'")

    // Check if list exists
    let calendars = eventStore.calendars(for: .reminder)
    print("[MurmerRemindersTool.getOrCreateList] Found \(calendars.count) reminder calendars")

    for (index, cal) in calendars.enumerated() {
      print(
        "[MurmerRemindersTool.getOrCreateList]   Calendar \(index): '\(cal.title)' (ID: \(cal.calendarIdentifier))"
      )
    }

    if let existingCalendar = calendars.first(where: { $0.title.lowercased() == name.lowercased() })
    {
      print(
        "[MurmerRemindersTool.getOrCreateList] Found existing calendar: '\(existingCalendar.title)'"
      )
      return existingCalendar
    }

    print("[MurmerRemindersTool.getOrCreateList] No existing calendar found, creating new one...")

    // Create new list
    let newCalendar = EKCalendar(for: .reminder, eventStore: eventStore)
    newCalendar.title = name
    print("[MurmerRemindersTool.getOrCreateList] Created new calendar object with title: '\(name)'")

    let defaultCalendar = eventStore.defaultCalendarForNewReminders()
    print(
      "[MurmerRemindersTool.getOrCreateList] Default calendar: \(defaultCalendar?.title ?? "nil")")

    newCalendar.source = defaultCalendar?.source
    print(
      "[MurmerRemindersTool.getOrCreateList] Calendar source: \(newCalendar.source?.title ?? "nil")"
    )

    guard newCalendar.source != nil else {
      print("[MurmerRemindersTool.getOrCreateList] ERROR: No calendar source available")
      throw MurmerError.cannotCreateList
    }

    print("[MurmerRemindersTool.getOrCreateList] Attempting to save new calendar...")
    do {
      try eventStore.saveCalendar(newCalendar, commit: true)
      print(
        "[MurmerRemindersTool.getOrCreateList] Successfully saved new calendar: '\(newCalendar.title)'"
      )
    } catch {
      print("[MurmerRemindersTool.getOrCreateList] ERROR saving calendar: \(error)")
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
