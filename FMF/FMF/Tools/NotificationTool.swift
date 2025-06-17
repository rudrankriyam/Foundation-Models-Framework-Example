//
//  NotificationTool.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/17/25.
//

import Foundation
import FoundationModels
import UserNotifications

/// `NotificationTool` provides functionality to schedule and manage local notifications.
///
/// This tool can schedule notifications, query pending notifications, and manage notification permissions.
/// It requires appropriate permissions to schedule notifications.
struct NotificationTool: Tool {
  
  /// The name of the tool, used for identification.
  let name = "manageNotifications"
  /// A brief description of the tool's functionality.
  let description = "Schedule local notifications, query pending notifications, and manage notification settings"
  
  /// Arguments for notification operations.
  @Generable
  struct Arguments {
    /// The action to perform: "schedule", "query", "cancel", "checkPermission"
    @Guide(description: "The action to perform: 'schedule', 'query', 'cancel', 'checkPermission'")
    var action: String
    
    /// Title of the notification
    @Guide(description: "Title of the notification")
    var title: String?
    
    /// Body/content of the notification
    @Guide(description: "Body/content of the notification")
    var body: String?
    
    /// Subtitle of the notification (optional)
    @Guide(description: "Subtitle of the notification (optional)")
    var subtitle: String?
    
    /// Notification identifier (for cancellation)
    @Guide(description: "Notification identifier (for cancellation)")
    var notificationId: String?
    
    /// Trigger type: "timeInterval", "calendar", "location"
    @Guide(description: "Trigger type: 'timeInterval', 'calendar', 'location'")
    var triggerType: String?
    
    /// Time interval in seconds (for timeInterval trigger)
    @Guide(description: "Time interval in seconds (for timeInterval trigger)")
    var timeInterval: Double?
    
    /// Date/time in ISO 8601 format (for calendar trigger)
    @Guide(description: "Date/time in ISO 8601 format (for calendar trigger)")
    var dateTime: String?
    
    /// Whether the notification should repeat
    @Guide(description: "Whether the notification should repeat")
    var repeats: Bool?
    
    /// Category identifier for actionable notifications
    @Guide(description: "Category identifier for actionable notifications")
    var categoryIdentifier: String?
    
    /// Sound name (default uses system sound)
    @Guide(description: "Sound name (default uses system sound)")
    var soundName: String?
    
    /// Badge number to display on app icon
    @Guide(description: "Badge number to display on app icon")
    var badge: Int?
  }
  
  /// Notification data structure
  struct NotificationData: Encodable {
    let id: String
    let title: String
    let body: String
    let subtitle: String?
    let triggerDescription: String
    let nextTriggerDate: String?
    let repeats: Bool
  }
  
  private let notificationCenter = UNUserNotificationCenter.current()
  
  func call(arguments: Arguments) async throws -> ToolOutput {
    switch arguments.action.lowercased() {
    case "schedule":
      return try await scheduleNotification(arguments: arguments)
    case "query":
      return try await queryNotifications()
    case "cancel":
      return try await cancelNotification(arguments: arguments)
    case "checkpermission":
      return try await checkNotificationPermission()
    default:
      return createErrorOutput(error: NotificationError.invalidAction)
    }
  }
  
  private func scheduleNotification(arguments: Arguments) async throws -> ToolOutput {
    // First check permission
    let settings = await notificationCenter.notificationSettings()
    guard settings.authorizationStatus == .authorized else {
      // Request permission if not authorized
      let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
      guard granted else {
        return createErrorOutput(error: NotificationError.permissionDenied)
      }
    }
    
    guard let title = arguments.title,
          let body = arguments.body else {
      return createErrorOutput(error: NotificationError.missingContent)
    }
    
    // Create notification content
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    
    if let subtitle = arguments.subtitle {
      content.subtitle = subtitle
    }
    
    if let categoryIdentifier = arguments.categoryIdentifier {
      content.categoryIdentifier = categoryIdentifier
    }
    
    if let soundName = arguments.soundName {
      content.sound = UNNotificationSound(named: UNNotificationSoundName(soundName))
    } else {
      content.sound = .default
    }
    
    if let badge = arguments.badge {
      content.badge = NSNumber(value: badge)
    }
    
    // Create trigger
    let trigger = try createTrigger(from: arguments)
    
    // Create request
    let identifier = arguments.notificationId ?? UUID().uuidString
    let request = UNNotificationRequest(
      identifier: identifier,
      content: content,
      trigger: trigger
    )
    
    // Schedule notification
    try await notificationCenter.add(request)
    
    let notificationData = NotificationData(
      id: identifier,
      title: title,
      body: body,
      subtitle: arguments.subtitle,
      triggerDescription: describeTrigger(trigger),
      nextTriggerDate: getNextTriggerDate(trigger),
      repeats: arguments.repeats ?? false
    )
    
    return createSuccessOutput(
      message: "Notification scheduled successfully",
      notifications: [notificationData]
    )
  }
  
  private func queryNotifications() async throws -> ToolOutput {
    let pendingRequests = await notificationCenter.pendingNotificationRequests()
    
    let notifications = pendingRequests.map { request in
      NotificationData(
        id: request.identifier,
        title: request.content.title,
        body: request.content.body,
        subtitle: request.content.subtitle.isEmpty ? nil : request.content.subtitle,
        triggerDescription: describeTrigger(request.trigger),
        nextTriggerDate: getNextTriggerDate(request.trigger),
        repeats: (request.trigger as? UNTimeIntervalNotificationTrigger)?.repeats ?? 
                 (request.trigger as? UNCalendarNotificationTrigger)?.repeats ?? false
      )
    }
    
    return createSuccessOutput(
      message: "Found \(notifications.count) pending notifications",
      notifications: notifications
    )
  }
  
  private func cancelNotification(arguments: Arguments) async throws -> ToolOutput {
    guard let notificationId = arguments.notificationId else {
      return createErrorOutput(error: NotificationError.missingNotificationId)
    }
    
    notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationId])
    
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "success",
        "message": "Notification cancelled successfully",
        "notificationId": notificationId
      ])
    )
  }
  
  private func checkNotificationPermission() async throws -> ToolOutput {
    let settings = await notificationCenter.notificationSettings()
    
    let status: String
    let isAuthorized: Bool
    
    switch settings.authorizationStatus {
    case .authorized:
      status = "authorized"
      isAuthorized = true
    case .denied:
      status = "denied"
      isAuthorized = false
    case .notDetermined:
      status = "notDetermined"
      isAuthorized = false
    case .provisional:
      status = "provisional"
      isAuthorized = true
    case .ephemeral:
      status = "ephemeral"
      isAuthorized = true
    @unknown default:
      status = "unknown"
      isAuthorized = false
    }
    
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "success",
        "authorizationStatus": status,
        "isAuthorized": isAuthorized,
        "alertEnabled": settings.alertSetting == .enabled,
        "soundEnabled": settings.soundSetting == .enabled,
        "badgeEnabled": settings.badgeSetting == .enabled,
        "criticalAlertEnabled": settings.criticalAlertSetting == .enabled
      ])
    )
  }
  
  private func createTrigger(from arguments: Arguments) throws -> UNNotificationTrigger? {
    let triggerType = arguments.triggerType ?? "timeInterval"
    let repeats = arguments.repeats ?? false
    
    switch triggerType.lowercased() {
    case "timeinterval":
      guard let interval = arguments.timeInterval else {
        throw NotificationError.missingTimeInterval
      }
      return UNTimeIntervalNotificationTrigger(
        timeInterval: interval,
        repeats: repeats
      )
      
    case "calendar":
      guard let dateTimeString = arguments.dateTime,
            let date = ISO8601DateFormatter().date(from: dateTimeString) else {
        throw NotificationError.invalidDateTime
      }
      
      let calendar = Calendar.current
      let components = calendar.dateComponents(
        [.year, .month, .day, .hour, .minute],
        from: date
      )
      
      return UNCalendarNotificationTrigger(
        dateMatching: components,
        repeats: repeats
      )
      
    default:
      // Default to immediate delivery (1 second)
      return UNTimeIntervalNotificationTrigger(
        timeInterval: 1,
        repeats: false
      )
    }
  }
  
  private func describeTrigger(_ trigger: UNNotificationTrigger?) -> String {
    guard let trigger = trigger else {
      return "Immediate"
    }
    
    if let timeIntervalTrigger = trigger as? UNTimeIntervalNotificationTrigger {
      let interval = timeIntervalTrigger.timeInterval
      let repeats = timeIntervalTrigger.repeats ? " (repeating)" : ""
      
      if interval < 60 {
        return "\(Int(interval)) seconds\(repeats)"
      } else if interval < 3600 {
        return "\(Int(interval / 60)) minutes\(repeats)"
      } else {
        return "\(Int(interval / 3600)) hours\(repeats)"
      }
    } else if let calendarTrigger = trigger as? UNCalendarNotificationTrigger {
      let components = calendarTrigger.dateComponents
      let repeats = calendarTrigger.repeats ? " (repeating)" : ""
      
      if let date = Calendar.current.date(from: components) {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date) + repeats
      }
      
      return "Calendar trigger\(repeats)"
    }
    
    return "Unknown trigger"
  }
  
  private func getNextTriggerDate(_ trigger: UNNotificationTrigger?) -> String? {
    guard let trigger = trigger else { return nil }
    
    if let timeIntervalTrigger = trigger as? UNTimeIntervalNotificationTrigger {
      let nextDate = Date().addingTimeInterval(timeIntervalTrigger.timeInterval)
      return ISO8601DateFormatter().string(from: nextDate)
    } else if let calendarTrigger = trigger as? UNCalendarNotificationTrigger,
              let date = calendarTrigger.nextTriggerDate() {
      return ISO8601DateFormatter().string(from: date)
    }
    
    return nil
  }
  
  private func createSuccessOutput(message: String, notifications: [NotificationData]) -> ToolOutput {
    var properties: [String: Any] = [
      "status": "success",
      "message": message,
      "count": notifications.count
    ]
    
    if !notifications.isEmpty {
      properties["notifications"] = notifications.map { notification in
        var notificationDict: [String: Any] = [
          "id": notification.id,
          "title": notification.title,
          "body": notification.body,
          "triggerDescription": notification.triggerDescription,
          "repeats": notification.repeats
        ]
        
        if let subtitle = notification.subtitle {
          notificationDict["subtitle"] = subtitle
        }
        
        if let nextTriggerDate = notification.nextTriggerDate {
          notificationDict["nextTriggerDate"] = nextTriggerDate
        }
        
        return notificationDict
      }
    }
    
    return ToolOutput(GeneratedContent(properties: properties))
  }
  
  private func createErrorOutput(error: Error) -> ToolOutput {
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "error",
        "error": error.localizedDescription,
        "message": "Failed to perform notification operation"
      ])
    )
  }
}

enum NotificationError: Error, LocalizedError {
  case invalidAction
  case permissionDenied
  case missingContent
  case missingNotificationId
  case missingTimeInterval
  case invalidDateTime
  
  var errorDescription: String? {
    switch self {
    case .invalidAction:
      return "Invalid action. Use 'schedule', 'query', 'cancel', or 'checkPermission'."
    case .permissionDenied:
      return "Notification permission denied. Please grant permission in Settings."
    case .missingContent:
      return "Title and body are required for scheduling a notification."
    case .missingNotificationId:
      return "Notification ID is required for cancellation."
    case .missingTimeInterval:
      return "Time interval is required for time-based triggers."
    case .invalidDateTime:
      return "Invalid date/time format. Use ISO 8601 format."
    }
  }
}