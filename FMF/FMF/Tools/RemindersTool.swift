//
//  RemindersTool.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/17/25.
//

import EventKit
import Foundation
import FoundationModels

/// `RemindersTool` provides access to the Reminders app data using EventKit.
///
/// This tool can create, read, update, and query reminders from the user's Reminders app.
/// It requires appropriate permissions to access reminder data.
struct RemindersTool: Tool {
  
  /// The name of the tool, used for identification.
  let name = "manageReminders"
  /// A brief description of the tool's functionality.
  let description = "Create, read, update, or query reminders from the Reminders app"
  
  /// Arguments for reminder operations.
  @Generable
  struct Arguments {
    /// The action to perform: "create", "read", "update", "complete", or "query"
    @Guide(description: "The action to perform: 'create', 'read', 'update', 'complete', or 'query'")
    var action: String
    
    /// The title of the reminder (for create/update actions)
    @Guide(description: "The title of the reminder (for create/update actions)")
    var title: String?
    
    /// Notes or description for the reminder
    @Guide(description: "Notes or description for the reminder")
    var notes: String?
    
    /// Due date in ISO 8601 format (e.g., "2025-06-17T14:30:00Z")
    @Guide(description: "Due date in ISO 8601 format (e.g., '2025-06-17T14:30:00Z')")
    var dueDate: String?
    
    /// Priority level: "none", "low", "medium", "high"
    @Guide(description: "Priority level: 'none', 'low', 'medium', 'high'")
    var priority: String?
    
    /// List name to add the reminder to
    @Guide(description: "List name to add the reminder to")
    var listName: String?
    
    /// Reminder ID for update/complete actions
    @Guide(description: "Reminder ID for update/complete actions")
    var reminderId: String?
    
    /// Query filter: "all", "incomplete", "completed", "today", "overdue"
    @Guide(description: "Query filter: 'all', 'incomplete', 'completed', 'today', 'overdue'")
    var filter: String?
  }
  
  /// Reminder data structure
  struct ReminderData: Encodable {
    let id: String
    let title: String
    let notes: String?
    let isCompleted: Bool
    let dueDate: String?
    let priority: String
    let listName: String?
  }
  
  private let eventStore = EKEventStore()
  
  func call(arguments: Arguments) async throws -> ToolOutput {
    // Request access to reminders
    let granted = try await requestRemindersAccess()
    guard granted else {
      return createErrorOutput(error: RemindersError.accessDenied)
    }
    
    switch arguments.action.lowercased() {
    case "create":
      return try await createReminder(arguments: arguments)
    case "read":
      return try await readReminder(arguments: arguments)
    case "update":
      return try await updateReminder(arguments: arguments)
    case "complete":
      return try await completeReminder(arguments: arguments)
    case "query":
      return try await queryReminders(arguments: arguments)
    default:
      return createErrorOutput(error: RemindersError.invalidAction)
    }
  }
  
  private func requestRemindersAccess() async throws -> Bool {
    if #available(iOS 17.0, macOS 14.0, *) {
      return try await eventStore.requestFullAccessToReminders()
    } else {
      return try await eventStore.requestAccess(to: .reminder)
    }
  }
  
  private func createReminder(arguments: Arguments) async throws -> ToolOutput {
    guard let title = arguments.title else {
      return createErrorOutput(error: RemindersError.missingTitle)
    }
    
    let reminder = EKReminder(eventStore: eventStore)
    reminder.title = title
    reminder.notes = arguments.notes
    
    if let dueDateString = arguments.dueDate,
       let dueDate = ISO8601DateFormatter().date(from: dueDateString) {
      reminder.dueDateComponents = Calendar.current.dateComponents(
        [.year, .month, .day, .hour, .minute],
        from: dueDate
      )
    }
    
    if let priorityString = arguments.priority {
      reminder.priority = priorityFromString(priorityString)
    }
    
    if let listName = arguments.listName {
      let calendars = eventStore.calendars(for: .reminder)
      if let calendar = calendars.first(where: { $0.title == listName }) {
        reminder.calendar = calendar
      } else {
        reminder.calendar = eventStore.defaultCalendarForNewReminders()
      }
    } else {
      reminder.calendar = eventStore.defaultCalendarForNewReminders()
    }
    
    try eventStore.save(reminder, commit: true)
    
    let reminderData = ReminderData(
      id: reminder.calendarItemIdentifier,
      title: reminder.title ?? "",
      notes: reminder.notes,
      isCompleted: reminder.isCompleted,
      dueDate: arguments.dueDate,
      priority: priorityToString(reminder.priority),
      listName: reminder.calendar?.title
    )
    
    return createSuccessOutput(
      message: "Reminder created successfully",
      reminders: [reminderData]
    )
  }
  
  private func readReminder(arguments: Arguments) async throws -> ToolOutput {
    guard let reminderId = arguments.reminderId else {
      return createErrorOutput(error: RemindersError.missingReminderId)
    }
    
    guard let reminder = eventStore.calendarItem(withIdentifier: reminderId) as? EKReminder else {
      return createErrorOutput(error: RemindersError.reminderNotFound)
    }
    
    let reminderData = ReminderData(
      id: reminder.calendarItemIdentifier,
      title: reminder.title ?? "",
      notes: reminder.notes,
      isCompleted: reminder.isCompleted,
      dueDate: reminder.dueDateComponents.flatMap { dateComponentsToISO8601($0) },
      priority: priorityToString(reminder.priority),
      listName: reminder.calendar?.title
    )
    
    return createSuccessOutput(
      message: "Reminder retrieved successfully",
      reminders: [reminderData]
    )
  }
  
  private func updateReminder(arguments: Arguments) async throws -> ToolOutput {
    guard let reminderId = arguments.reminderId else {
      return createErrorOutput(error: RemindersError.missingReminderId)
    }
    
    guard let reminder = eventStore.calendarItem(withIdentifier: reminderId) as? EKReminder else {
      return createErrorOutput(error: RemindersError.reminderNotFound)
    }
    
    if let title = arguments.title {
      reminder.title = title
    }
    
    if let notes = arguments.notes {
      reminder.notes = notes
    }
    
    if let dueDateString = arguments.dueDate,
       let dueDate = ISO8601DateFormatter().date(from: dueDateString) {
      reminder.dueDateComponents = Calendar.current.dateComponents(
        [.year, .month, .day, .hour, .minute],
        from: dueDate
      )
    }
    
    if let priorityString = arguments.priority {
      reminder.priority = priorityFromString(priorityString)
    }
    
    try eventStore.save(reminder, commit: true)
    
    let reminderData = ReminderData(
      id: reminder.calendarItemIdentifier,
      title: reminder.title ?? "",
      notes: reminder.notes,
      isCompleted: reminder.isCompleted,
      dueDate: reminder.dueDateComponents.flatMap { dateComponentsToISO8601($0) },
      priority: priorityToString(reminder.priority),
      listName: reminder.calendar?.title
    )
    
    return createSuccessOutput(
      message: "Reminder updated successfully",
      reminders: [reminderData]
    )
  }
  
  private func completeReminder(arguments: Arguments) async throws -> ToolOutput {
    guard let reminderId = arguments.reminderId else {
      return createErrorOutput(error: RemindersError.missingReminderId)
    }
    
    guard let reminder = eventStore.calendarItem(withIdentifier: reminderId) as? EKReminder else {
      return createErrorOutput(error: RemindersError.reminderNotFound)
    }
    
    reminder.isCompleted = true
    reminder.completionDate = Date()
    
    try eventStore.save(reminder, commit: true)
    
    return createSuccessOutput(
      message: "Reminder marked as completed",
      reminders: []
    )
  }
  
  private func queryReminders(arguments: Arguments) async throws -> ToolOutput {
    let filter = arguments.filter ?? "all"
    let predicate = createPredicate(for: filter)
    
    let reminders = try await withCheckedThrowingContinuation { continuation in
      eventStore.fetchReminders(matching: predicate) { reminders in
        if let reminders = reminders {
          continuation.resume(returning: reminders)
        } else {
          continuation.resume(throwing: RemindersError.fetchFailed)
        }
      }
    }
    
    let reminderDataArray = reminders.map { reminder in
      ReminderData(
        id: reminder.calendarItemIdentifier,
        title: reminder.title ?? "",
        notes: reminder.notes,
        isCompleted: reminder.isCompleted,
        dueDate: reminder.dueDateComponents.flatMap { dateComponentsToISO8601($0) },
        priority: priorityToString(reminder.priority),
        listName: reminder.calendar?.title
      )
    }
    
    return createSuccessOutput(
      message: "Found \(reminderDataArray.count) reminders",
      reminders: reminderDataArray
    )
  }
  
  private func createPredicate(for filter: String) -> NSPredicate {
    let calendars = eventStore.calendars(for: .reminder)
    
    switch filter.lowercased() {
    case "incomplete":
      return eventStore.predicateForIncompleteReminders(
        withDueDateStarting: nil,
        ending: nil,
        calendars: calendars
      )
    case "completed":
      return eventStore.predicateForCompletedReminders(
        withCompletionDateStarting: nil,
        ending: nil,
        calendars: calendars
      )
    case "today":
      let startOfDay = Calendar.current.startOfDay(for: Date())
      let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
      return eventStore.predicateForIncompleteReminders(
        withDueDateStarting: startOfDay,
        ending: endOfDay,
        calendars: calendars
      )
    case "overdue":
      return eventStore.predicateForIncompleteReminders(
        withDueDateStarting: nil,
        ending: Date(),
        calendars: calendars
      )
    default: // "all"
      return eventStore.predicateForReminders(in: calendars)
    }
  }
  
  private func priorityFromString(_ priority: String) -> Int {
    switch priority.lowercased() {
    case "high": return 1
    case "medium": return 5
    case "low": return 9
    default: return 0 // none
    }
  }
  
  private func priorityToString(_ priority: Int) -> String {
    switch priority {
    case 1...3: return "high"
    case 4...6: return "medium"
    case 7...9: return "low"
    default: return "none"
    }
  }
  
  private func dateComponentsToISO8601(_ components: DateComponents) -> String? {
    guard let date = Calendar.current.date(from: components) else { return nil }
    return ISO8601DateFormatter().string(from: date)
  }
  
  private func createSuccessOutput(message: String, reminders: [ReminderData]) -> ToolOutput {
    var properties: [String: Any] = [
      "status": "success",
      "message": message,
      "count": reminders.count
    ]
    
    if !reminders.isEmpty {
      properties["reminders"] = reminders.map { reminder in
        [
          "id": reminder.id,
          "title": reminder.title,
          "notes": reminder.notes ?? "",
          "isCompleted": reminder.isCompleted,
          "dueDate": reminder.dueDate ?? "",
          "priority": reminder.priority,
          "listName": reminder.listName ?? ""
        ]
      }
    }
    
    return ToolOutput(GeneratedContent(properties: properties))
  }
  
  private func createErrorOutput(error: Error) -> ToolOutput {
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "error",
        "error": error.localizedDescription,
        "message": "Failed to perform reminder operation"
      ])
    )
  }
}

enum RemindersError: Error, LocalizedError {
  case accessDenied
  case invalidAction
  case missingTitle
  case missingReminderId
  case reminderNotFound
  case fetchFailed
  
  var errorDescription: String? {
    switch self {
    case .accessDenied:
      return "Access to reminders denied. Please grant permission in Settings."
    case .invalidAction:
      return "Invalid action. Use 'create', 'read', 'update', 'complete', or 'query'."
    case .missingTitle:
      return "Title is required for creating a reminder."
    case .missingReminderId:
      return "Reminder ID is required for this operation."
    case .reminderNotFound:
      return "Reminder not found with the provided ID."
    case .fetchFailed:
      return "Failed to fetch reminders."
    }
  }
}