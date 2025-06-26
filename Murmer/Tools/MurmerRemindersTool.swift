//
//  MurmerRemindersTool.swift
//  Murmer
//
//  Created by Rudrank Riyam on 6/26/25.
//

import Foundation
import EventKit
import FoundationModels

struct MurmerRemindersTool: Tool {
    let name = "createReminder"
    let description = "Create a reminder from voice input"
    
    @Generable
    struct Arguments {
        @Guide(description: "The reminder text from voice input")
        var text: String
        
        @Guide(description: "Optional due date/time parsed from speech (e.g., 'tomorrow at 3pm', 'in 2 hours')")
        var timeExpression: String?
        
        @Guide(description: "The reminder list name (defaults to default list)")
        var listName: String?
    }
    
    private let eventStore = EKEventStore()
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        // Create reminder
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = arguments.text
        
        // Parse time expression if provided
        if let timeExpression = arguments.timeExpression {
            if let dueDate = parseTimeExpression(timeExpression) {
                reminder.dueDateComponents = Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: dueDate
                )
                
                // Add alarm for the due date
                let alarm = EKAlarm(absoluteDate: dueDate)
                reminder.addAlarm(alarm)
            }
        }
        
        // Get the appropriate calendar
        let calendar: EKCalendar
        if let listName = arguments.listName {
            calendar = try await getOrCreateList(named: listName)
        } else {
            guard let defaultCalendar = eventStore.defaultCalendarForNewReminders() else {
                throw MurmerError.noDefaultList
            }
            calendar = defaultCalendar
        }
        
        reminder.calendar = calendar
        
        // Save the reminder
        try eventStore.save(reminder, commit: true)
        
        let output = ReminderOutput(
            id: reminder.calendarItemIdentifier,
            title: reminder.title ?? "",
            dueDate: reminder.dueDateComponents?.date,
            listName: calendar.title,
            success: true,
            message: "Reminder created successfully"
        )
        
        return ToolOutput(output.generatedContent)
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
            
            return calendar.date(byAdding: components, to: calendar.startOfDay(for: now))
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
                return calendar.date(byAdding: .hour, value: hours, to: now)
            }
            if let minutes = extractNumber(from: lowercased, unit: "minute") {
                return calendar.date(byAdding: .minute, value: minutes, to: now)
            }
            if let days = extractNumber(from: lowercased, unit: "day") {
                return calendar.date(byAdding: .day, value: days, to: now)
            }
        }
        
        // Handle next week
        if lowercased.contains("next week") {
            return calendar.date(byAdding: .weekOfYear, value: 1, to: now)
        }
        
        // Handle day names
        let dayNames = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
        for (index, dayName) in dayNames.enumerated() {
            if lowercased.contains(dayName) {
                let weekday = index + 1 // Sunday = 1
                return nextOccurrence(of: weekday, from: now)
            }
        }
        
        return nil
    }
    
    private func extractTime(from text: String) -> (hour: Int, minute: Int)? {
        // Match patterns like "3pm", "3:30pm", "15:30"
        let patterns = [
            #"(\d{1,2}):(\d{2})\s*(am|pm)?"#,
            #"(\d{1,2})\s*(am|pm)"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
                
                if let match = matches.first {
                    if match.numberOfRanges >= 2,
                       let hourRange = Range(match.range(at: 1), in: text),
                       let hour = Int(text[hourRange]) {
                        
                        var finalHour = hour
                        var minute = 0
                        
                        // Extract minutes if present
                        if match.numberOfRanges >= 3,
                           let minuteRange = Range(match.range(at: 2), in: text) {
                            minute = Int(text[minuteRange]) ?? 0
                        }
                        
                        // Handle AM/PM
                        if match.numberOfRanges >= 3 {
                            let amPmIndex = match.numberOfRanges == 4 ? 3 : 2
                            if let amPmRange = Range(match.range(at: amPmIndex), in: text) {
                                let amPm = text[amPmRange].lowercased()
                                if amPm == "pm" && finalHour < 12 {
                                    finalHour += 12
                                } else if amPm == "am" && finalHour == 12 {
                                    finalHour = 0
                                }
                            }
                        }
                        
                        return (finalHour, minute)
                    }
                }
            }
        }
        
        return nil
    }
    
    private func extractNumber(from text: String, unit: String) -> Int? {
        let pattern = #"(\d+)\s*"# + unit
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            
            if let match = matches.first,
               let numberRange = Range(match.range(at: 1), in: text),
               let number = Int(text[numberRange]) {
                return number
            }
        }
        
        // Handle written numbers
        let writtenNumbers = [
            "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
            "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10
        ]
        
        for (written, value) in writtenNumbers {
            if text.contains("\(written) \(unit)") {
                return value
            }
        }
        
        return nil
    }
    
    private func nextOccurrence(of weekday: Int, from date: Date) -> Date? {
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: date)
        
        var daysToAdd = weekday - currentWeekday
        if daysToAdd <= 0 {
            daysToAdd += 7
        }
        
        return calendar.date(byAdding: .day, value: daysToAdd, to: date)
    }
    
    private func getOrCreateList(named name: String) async throws -> EKCalendar {
        // Check if list exists
        let calendars = eventStore.calendars(for: .reminder)
        if let existingCalendar = calendars.first(where: { $0.title.lowercased() == name.lowercased() }) {
            return existingCalendar
        }
        
        // Create new list
        let newCalendar = EKCalendar(for: .reminder, eventStore: eventStore)
        newCalendar.title = name
        newCalendar.source = eventStore.defaultCalendarForNewReminders()?.source
        
        guard newCalendar.source != nil else {
            throw MurmerError.cannotCreateList
        }
        
        try eventStore.saveCalendar(newCalendar, commit: true)
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
            "message": message
        ])
    }
}

// MARK: - Errors
enum MurmerError: LocalizedError {
    case noDefaultList
    case cannotCreateList
    
    var errorDescription: String? {
        switch self {
        case .noDefaultList:
            return "No default reminders list found"
        case .cannotCreateList:
            return "Cannot create new reminders list"
        }
    }
}