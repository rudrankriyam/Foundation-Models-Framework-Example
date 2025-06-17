//
//  CalendarTool.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/17/25.
//

import EventKit
import Foundation
import FoundationModels

/// `CalendarTool` provides access to calendar events using EventKit.
///
/// This tool can create, read, update, and query calendar events.
/// It requires appropriate permissions to access calendar data.
struct CalendarTool: Tool {
  
  /// The name of the tool, used for identification.
  let name = "manageCalendar"
  /// A brief description of the tool's functionality.
  let description = "Create, read, update, or query calendar events"
  
  /// Arguments for calendar operations.
  @Generable
  struct Arguments {
    /// The action to perform: "create", "read", "update", "delete", "query", or "checkAvailability"
    @Guide(description: "The action to perform: 'create', 'read', 'update', 'delete', 'query', or 'checkAvailability'")
    var action: String
    
    /// The title of the event
    @Guide(description: "The title of the event")
    var title: String?
    
    /// Location of the event
    @Guide(description: "Location of the event")
    var location: String?
    
    /// Notes or description for the event
    @Guide(description: "Notes or description for the event")
    var notes: String?
    
    /// Start date in ISO 8601 format (e.g., "2025-06-17T14:30:00Z")
    @Guide(description: "Start date in ISO 8601 format (e.g., '2025-06-17T14:30:00Z')")
    var startDate: String?
    
    /// End date in ISO 8601 format
    @Guide(description: "End date in ISO 8601 format")
    var endDate: String?
    
    /// Calendar name to add the event to
    @Guide(description: "Calendar name to add the event to")
    var calendarName: String?
    
    /// Event ID for read/update/delete actions
    @Guide(description: "Event ID for read/update/delete actions")
    var eventId: String?
    
    /// Query time range: "today", "tomorrow", "thisWeek", "nextWeek", or custom dates
    @Guide(description: "Query time range: 'today', 'tomorrow', 'thisWeek', 'nextWeek', or custom dates")
    var timeRange: String?
    
    /// Recurrence rule: "daily", "weekly", "monthly", "yearly"
    @Guide(description: "Recurrence rule: 'daily', 'weekly', 'monthly', 'yearly'")
    var recurrence: String?
    
    /// Number of occurrences for recurring events
    @Guide(description: "Number of occurrences for recurring events")
    var occurrences: Int?
  }
  
  /// Event data structure
  struct EventData: Encodable {
    let id: String
    let title: String
    let location: String?
    let notes: String?
    let startDate: String
    let endDate: String
    let calendarName: String?
    let isAllDay: Bool
    let hasRecurrence: Bool
  }
  
  private let eventStore = EKEventStore()
  private let dateFormatter = ISO8601DateFormatter()
  
  func call(arguments: Arguments) async throws -> ToolOutput {
    // Request access to calendar
    let granted = try await requestCalendarAccess()
    guard granted else {
      return createErrorOutput(error: CalendarError.accessDenied)
    }
    
    switch arguments.action.lowercased() {
    case "create":
      return try await createEvent(arguments: arguments)
    case "read":
      return try await readEvent(arguments: arguments)
    case "update":
      return try await updateEvent(arguments: arguments)
    case "delete":
      return try await deleteEvent(arguments: arguments)
    case "query":
      return try await queryEvents(arguments: arguments)
    case "checkavailability":
      return try await checkAvailability(arguments: arguments)
    default:
      return createErrorOutput(error: CalendarError.invalidAction)
    }
  }
  
  private func requestCalendarAccess() async throws -> Bool {
    if #available(iOS 17.0, macOS 14.0, *) {
      return try await eventStore.requestFullAccessToEvents()
    } else {
      return try await eventStore.requestAccess(to: .event)
    }
  }
  
  private func createEvent(arguments: Arguments) async throws -> ToolOutput {
    guard let title = arguments.title,
          let startDateString = arguments.startDate,
          let endDateString = arguments.endDate,
          let startDate = dateFormatter.date(from: startDateString),
          let endDate = dateFormatter.date(from: endDateString) else {
      return createErrorOutput(error: CalendarError.missingRequiredFields)
    }
    
    let event = EKEvent(eventStore: eventStore)
    event.title = title
    event.location = arguments.location
    event.notes = arguments.notes
    event.startDate = startDate
    event.endDate = endDate
    
    // Set calendar
    if let calendarName = arguments.calendarName {
      let calendars = eventStore.calendars(for: .event)
      if let calendar = calendars.first(where: { $0.title == calendarName }) {
        event.calendar = calendar
      } else {
        event.calendar = eventStore.defaultCalendarForNewEvents
      }
    } else {
      event.calendar = eventStore.defaultCalendarForNewEvents
    }
    
    // Add recurrence if specified
    if let recurrence = arguments.recurrence {
      event.addRecurrenceRule(createRecurrenceRule(
        recurrence: recurrence,
        occurrences: arguments.occurrences
      ))
    }
    
    try eventStore.save(event, span: .thisEvent)
    
    let eventData = EventData(
      id: event.eventIdentifier ?? "",
      title: event.title ?? "",
      location: event.location,
      notes: event.notes,
      startDate: dateFormatter.string(from: event.startDate),
      endDate: dateFormatter.string(from: event.endDate),
      calendarName: event.calendar?.title,
      isAllDay: event.isAllDay,
      hasRecurrence: event.hasRecurrenceRules
    )
    
    return createSuccessOutput(
      message: "Event created successfully",
      events: [eventData]
    )
  }
  
  private func readEvent(arguments: Arguments) async throws -> ToolOutput {
    guard let eventId = arguments.eventId else {
      return createErrorOutput(error: CalendarError.missingEventId)
    }
    
    guard let event = eventStore.event(withIdentifier: eventId) else {
      return createErrorOutput(error: CalendarError.eventNotFound)
    }
    
    let eventData = EventData(
      id: event.eventIdentifier ?? "",
      title: event.title ?? "",
      location: event.location,
      notes: event.notes,
      startDate: dateFormatter.string(from: event.startDate),
      endDate: dateFormatter.string(from: event.endDate),
      calendarName: event.calendar?.title,
      isAllDay: event.isAllDay,
      hasRecurrence: event.hasRecurrenceRules
    )
    
    return createSuccessOutput(
      message: "Event retrieved successfully",
      events: [eventData]
    )
  }
  
  private func updateEvent(arguments: Arguments) async throws -> ToolOutput {
    guard let eventId = arguments.eventId else {
      return createErrorOutput(error: CalendarError.missingEventId)
    }
    
    guard let event = eventStore.event(withIdentifier: eventId) else {
      return createErrorOutput(error: CalendarError.eventNotFound)
    }
    
    if let title = arguments.title {
      event.title = title
    }
    
    if let location = arguments.location {
      event.location = location
    }
    
    if let notes = arguments.notes {
      event.notes = notes
    }
    
    if let startDateString = arguments.startDate,
       let startDate = dateFormatter.date(from: startDateString) {
      event.startDate = startDate
    }
    
    if let endDateString = arguments.endDate,
       let endDate = dateFormatter.date(from: endDateString) {
      event.endDate = endDate
    }
    
    try eventStore.save(event, span: .thisEvent)
    
    let eventData = EventData(
      id: event.eventIdentifier ?? "",
      title: event.title ?? "",
      location: event.location,
      notes: event.notes,
      startDate: dateFormatter.string(from: event.startDate),
      endDate: dateFormatter.string(from: event.endDate),
      calendarName: event.calendar?.title,
      isAllDay: event.isAllDay,
      hasRecurrence: event.hasRecurrenceRules
    )
    
    return createSuccessOutput(
      message: "Event updated successfully",
      events: [eventData]
    )
  }
  
  private func deleteEvent(arguments: Arguments) async throws -> ToolOutput {
    guard let eventId = arguments.eventId else {
      return createErrorOutput(error: CalendarError.missingEventId)
    }
    
    guard let event = eventStore.event(withIdentifier: eventId) else {
      return createErrorOutput(error: CalendarError.eventNotFound)
    }
    
    try eventStore.remove(event, span: .thisEvent)
    
    return createSuccessOutput(
      message: "Event deleted successfully",
      events: []
    )
  }
  
  private func queryEvents(arguments: Arguments) async throws -> ToolOutput {
    let (startDate, endDate) = getDateRange(from: arguments.timeRange ?? "today")
    let calendars = eventStore.calendars(for: .event)
    
    let predicate = eventStore.predicateForEvents(
      withStart: startDate,
      end: endDate,
      calendars: calendars
    )
    
    let events = eventStore.events(matching: predicate)
    
    let eventDataArray = events.map { event in
      EventData(
        id: event.eventIdentifier ?? "",
        title: event.title ?? "",
        location: event.location,
        notes: event.notes,
        startDate: dateFormatter.string(from: event.startDate),
        endDate: dateFormatter.string(from: event.endDate),
        calendarName: event.calendar?.title,
        isAllDay: event.isAllDay,
        hasRecurrence: event.hasRecurrenceRules
      )
    }
    
    return createSuccessOutput(
      message: "Found \(eventDataArray.count) events",
      events: eventDataArray
    )
  }
  
  private func checkAvailability(arguments: Arguments) async throws -> ToolOutput {
    guard let startDateString = arguments.startDate,
          let endDateString = arguments.endDate,
          let startDate = dateFormatter.date(from: startDateString),
          let endDate = dateFormatter.date(from: endDateString) else {
      return createErrorOutput(error: CalendarError.missingRequiredFields)
    }
    
    let calendars = eventStore.calendars(for: .event)
    let predicate = eventStore.predicateForEvents(
      withStart: startDate,
      end: endDate,
      calendars: calendars
    )
    
    let events = eventStore.events(matching: predicate)
    let isAvailable = events.isEmpty
    
    var properties: [String: Any] = [
      "status": "success",
      "isAvailable": isAvailable,
      "startDate": startDateString,
      "endDate": endDateString,
      "conflictingEventsCount": events.count
    ]
    
    if !isAvailable {
      properties["conflictingEvents"] = events.prefix(5).map { event in
        [
          "title": event.title ?? "",
          "startDate": dateFormatter.string(from: event.startDate),
          "endDate": dateFormatter.string(from: event.endDate)
        ]
      }
    }
    
    return ToolOutput(GeneratedContent(properties: properties))
  }
  
  private func getDateRange(from timeRange: String) -> (start: Date, end: Date) {
    let calendar = Calendar.current
    let now = Date()
    
    switch timeRange.lowercased() {
    case "today":
      let start = calendar.startOfDay(for: now)
      let end = calendar.date(byAdding: .day, value: 1, to: start)!
      return (start, end)
    case "tomorrow":
      let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
      let start = calendar.startOfDay(for: tomorrow)
      let end = calendar.date(byAdding: .day, value: 1, to: start)!
      return (start, end)
    case "thisweek":
      let start = calendar.dateInterval(of: .weekOfYear, for: now)!.start
      let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start)!
      return (start, end)
    case "nextweek":
      let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: now)!
      let start = calendar.dateInterval(of: .weekOfYear, for: nextWeek)!.start
      let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start)!
      return (start, end)
    default:
      // Default to next 30 days
      let start = calendar.startOfDay(for: now)
      let end = calendar.date(byAdding: .day, value: 30, to: start)!
      return (start, end)
    }
  }
  
  private func createRecurrenceRule(recurrence: String, occurrences: Int?) -> EKRecurrenceRule {
    let frequency: EKRecurrenceFrequency
    
    switch recurrence.lowercased() {
    case "daily":
      frequency = .daily
    case "weekly":
      frequency = .weekly
    case "monthly":
      frequency = .monthly
    case "yearly":
      frequency = .yearly
    default:
      frequency = .weekly
    }
    
    let recurrenceEnd: EKRecurrenceEnd?
    if let count = occurrences {
      recurrenceEnd = EKRecurrenceEnd(occurrenceCount: count)
    } else {
      recurrenceEnd = nil
    }
    
    return EKRecurrenceRule(
      recurrenceWith: frequency,
      interval: 1,
      end: recurrenceEnd
    )
  }
  
  private func createSuccessOutput(message: String, events: [EventData]) -> ToolOutput {
    var properties: [String: Any] = [
      "status": "success",
      "message": message,
      "count": events.count
    ]
    
    if !events.isEmpty {
      properties["events"] = events.map { event in
        [
          "id": event.id,
          "title": event.title,
          "location": event.location ?? "",
          "notes": event.notes ?? "",
          "startDate": event.startDate,
          "endDate": event.endDate,
          "calendarName": event.calendarName ?? "",
          "isAllDay": event.isAllDay,
          "hasRecurrence": event.hasRecurrence
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
        "message": "Failed to perform calendar operation"
      ])
    )
  }
}

enum CalendarError: Error, LocalizedError {
  case accessDenied
  case invalidAction
  case missingRequiredFields
  case missingEventId
  case eventNotFound
  
  var errorDescription: String? {
    switch self {
    case .accessDenied:
      return "Access to calendar denied. Please grant permission in Settings."
    case .invalidAction:
      return "Invalid action. Use 'create', 'read', 'update', 'delete', 'query', or 'checkAvailability'."
    case .missingRequiredFields:
      return "Missing required fields. Title, start date, and end date are required."
    case .missingEventId:
      return "Event ID is required for this operation."
    case .eventNotFound:
      return "Event not found with the provided ID."
    }
  }
}