//
//  CalendarTool.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/17/25.
//

import Foundation
import FoundationModels
import EventKit

/// `CalendarTool` provides access to calendar events.
///
/// This tool can create, read, and query calendar events.
/// Important: This requires the Calendar entitlement and user permission.
struct CalendarTool: Tool {
  
  /// The name of the tool, used for identification.
  let name = "manageCalendar"
  /// A brief description of the tool's functionality.
  let description = "Create, read, and query calendar events"
  
  /// Arguments for calendar operations.
  @Generable
  struct Arguments {
    /// The action to perform: "create", "query", "read", "update"
    @Guide(description: "The action to perform: 'create', 'query', 'read', 'update'")
    var action: String
    
    /// Event title for creating or updating
    @Guide(description: "Event title for creating or updating")
    var title: String?
    
    /// Start date in ISO format (YYYY-MM-DD HH:mm:ss)
    @Guide(description: "Start date in ISO format (YYYY-MM-DD HH:mm:ss)")
    var startDate: String?
    
    /// End date in ISO format (YYYY-MM-DD HH:mm:ss)
    @Guide(description: "End date in ISO format (YYYY-MM-DD HH:mm:ss)")
    var endDate: String?
    
    /// Location for the event
    @Guide(description: "Location for the event")
    var location: String?
    
    /// Notes for the event
    @Guide(description: "Notes for the event")
    var notes: String?
    
    /// Calendar name to use (defaults to default calendar)
    @Guide(description: "Calendar name to use (defaults to default calendar)")
    var calendarName: String?
    
    /// Number of days to query (for query action)
    @Guide(description: "Number of days to query (for query action)")
    var daysAhead: Int?
    
    /// Event identifier for reading or updating specific event
    @Guide(description: "Event identifier for reading or updating specific event")
    var eventId: String?
  }
  
  private let eventStore = EKEventStore()
  
  func call(arguments: Arguments) async throws -> ToolOutput {
    // Request access if needed
    let authorized = await requestAccess()
    guard authorized else {
      return createErrorOutput(error: CalendarError.accessDenied)
    }
    
    switch arguments.action.lowercased() {
    case "create":
      return try createEvent(arguments: arguments)
    case "query":
      return try queryEvents(arguments: arguments)
    case "read":
      return try readEvent(eventId: arguments.eventId)
    case "update":
      return try updateEvent(arguments: arguments)
    default:
      return createErrorOutput(error: CalendarError.invalidAction)
    }
  }
  
  private func requestAccess() async -> Bool {
    do {
      if #available(macOS 14.0, iOS 17.0, *) {
        return try await eventStore.requestFullAccessToEvents()
      } else {
        return try await eventStore.requestAccess(to: .event)
      }
    } catch {
      return false
    }
  }
  
  private func createEvent(arguments: Arguments) throws -> ToolOutput {
    guard let title = arguments.title, !title.isEmpty else {
      return createErrorOutput(error: CalendarError.missingTitle)
    }
    
    guard let startDateString = arguments.startDate,
          let startDate = parseDate(startDateString) else {
      return createErrorOutput(error: CalendarError.invalidStartDate)
    }
    
    let endDate: Date
    if let endDateString = arguments.endDate {
      guard let parsedEndDate = parseDate(endDateString) else {
        return createErrorOutput(error: CalendarError.invalidEndDate)
      }
      endDate = parsedEndDate
    } else {
      // Default to 1 hour duration
      endDate = startDate.addingTimeInterval(3600)
    }
    
    let event = EKEvent(eventStore: eventStore)
    event.title = title
    event.startDate = startDate
    event.endDate = endDate
    
    if let location = arguments.location {
      event.location = location
    }
    
    if let notes = arguments.notes {
      event.notes = notes
    }
    
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
    
    do {
      try eventStore.save(event, span: .thisEvent)
      
      return ToolOutput(
        GeneratedContent(properties: [
          "status": "success",
          "message": "Event created successfully",
          "eventId": event.eventIdentifier ?? "",
          "title": event.title ?? "",
          "startDate": formatDate(event.startDate),
          "endDate": formatDate(event.endDate),
          "location": event.location ?? "",
          "calendar": event.calendar?.title ?? ""
        ])
      )
    } catch {
      return createErrorOutput(error: error)
    }
  }
  
  private func queryEvents(arguments: Arguments) throws -> ToolOutput {
    let startDate = Date()
    let daysToQuery = arguments.daysAhead ?? 7
    let endDate = Calendar.current.date(byAdding: .day, value: daysToQuery, to: startDate)!
    
    let calendars = eventStore.calendars(for: .event)
    
    let predicate = eventStore.predicateForEvents(
      withStart: startDate,
      end: endDate,
      calendars: calendars
    )
    
    let events = eventStore.events(matching: predicate)
    
    var eventsDescription = ""
    
    for (index, event) in events.enumerated() {
      let dateFormatter = DateFormatter()
      dateFormatter.dateStyle = .medium
      dateFormatter.timeStyle = .short
      
      let location = event.location != nil ? " at \(event.location!)" : ""
      let calendar = event.calendar?.title ?? "Unknown Calendar"
      
      eventsDescription += "\(index + 1). \(event.title ?? "Untitled")\n"
      eventsDescription += "   When: \(dateFormatter.string(from: event.startDate)) - \(dateFormatter.string(from: event.endDate))\n"
      eventsDescription += "   Calendar: \(calendar)\(location)\n"
      if let notes = event.notes, !notes.isEmpty {
        eventsDescription += "   Notes: \(notes.prefix(50))...\n"
      }
      eventsDescription += "\n"
    }
    
    if eventsDescription.isEmpty {
      eventsDescription = "No events found in the next \(daysToQuery) days"
    }
    
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "success",
        "count": events.count,
        "daysQueried": daysToQuery,
        "events": eventsDescription.trimmingCharacters(in: .whitespacesAndNewlines),
        "message": "Found \(events.count) event(s) in the next \(daysToQuery) days"
      ])
    )
  }
  
  private func readEvent(eventId: String?) throws -> ToolOutput {
    guard let id = eventId else {
      return createErrorOutput(error: CalendarError.missingEventId)
    }
    
    guard let event = eventStore.event(withIdentifier: id) else {
      return createErrorOutput(error: CalendarError.eventNotFound)
    }
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .full
    dateFormatter.timeStyle = .short
    
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "success",
        "eventId": event.eventIdentifier ?? "",
        "title": event.title ?? "",
        "startDate": formatDate(event.startDate),
        "endDate": formatDate(event.endDate),
        "location": event.location ?? "",
        "notes": event.notes ?? "",
        "calendar": event.calendar?.title ?? "",
        "isAllDay": event.isAllDay,
        "url": event.url?.absoluteString ?? "",
        "hasAlarms": !(event.alarms?.isEmpty ?? true),
        "formattedDate": "\(dateFormatter.string(from: event.startDate)) - \(dateFormatter.string(from: event.endDate))"
      ])
    )
  }
  
  private func updateEvent(arguments: Arguments) throws -> ToolOutput {
    guard let eventId = arguments.eventId else {
      return createErrorOutput(error: CalendarError.missingEventId)
    }
    
    guard let event = eventStore.event(withIdentifier: eventId) else {
      return createErrorOutput(error: CalendarError.eventNotFound)
    }
    
    // Update fields if provided
    if let title = arguments.title {
      event.title = title
    }
    
    if let startDateString = arguments.startDate,
       let startDate = parseDate(startDateString) {
      event.startDate = startDate
    }
    
    if let endDateString = arguments.endDate,
       let endDate = parseDate(endDateString) {
      event.endDate = endDate
    }
    
    if let location = arguments.location {
      event.location = location
    }
    
    if let notes = arguments.notes {
      event.notes = notes
    }
    
    do {
      try eventStore.save(event, span: .thisEvent)
      
      return ToolOutput(
        GeneratedContent(properties: [
          "status": "success",
          "message": "Event updated successfully",
          "eventId": event.eventIdentifier ?? "",
          "title": event.title ?? "",
          "startDate": formatDate(event.startDate),
          "endDate": formatDate(event.endDate),
          "location": event.location ?? "",
          "calendar": event.calendar?.title ?? ""
        ])
      )
    } catch {
      return createErrorOutput(error: error)
    }
  }
  
  private func parseDate(_ dateString: String) -> Date? {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    formatter.timeZone = TimeZone.current
    return formatter.date(from: dateString)
  }
  
  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    formatter.timeZone = TimeZone.current
    return formatter.string(from: date)
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
  case missingTitle
  case invalidStartDate
  case invalidEndDate
  case missingEventId
  case eventNotFound
  
  var errorDescription: String? {
    switch self {
    case .accessDenied:
      return "Access to calendar denied. Please grant permission in Settings."
    case .invalidAction:
      return "Invalid action. Use 'create', 'query', 'read', or 'update'."
    case .missingTitle:
      return "Title is required to create an event."
    case .invalidStartDate:
      return "Invalid start date format. Use YYYY-MM-DD HH:mm:ss"
    case .invalidEndDate:
      return "Invalid end date format. Use YYYY-MM-DD HH:mm:ss"
    case .missingEventId:
      return "Event ID is required."
    case .eventNotFound:
      return "Event not found with the provided ID."
    }
  }
}