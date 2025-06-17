//
//  TimerTool.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/17/25.
//

import Foundation
import FoundationModels

/// `TimerTool` provides functionality to work with time-based operations.
///
/// This tool can calculate time differences, format durations, and provide current time information.
struct TimerTool: Tool {
  
  /// The name of the tool, used for identification.
  let name = "timer"
  /// A brief description of the tool's functionality.
  let description = "Get current time, calculate time differences, and format durations"
  
  /// Arguments for timer operations.
  @Generable
  struct Arguments {
    /// The action to perform: "currentTime", "timeDifference", "formatDuration"
    @Guide(description: "The action to perform: 'currentTime', 'timeDifference', 'formatDuration'")
    var action: String
    
    /// Start time in ISO 8601 format (for timeDifference)
    @Guide(description: "Start time in ISO 8601 format (for timeDifference)")
    var startTime: String?
    
    /// End time in ISO 8601 format (for timeDifference)
    @Guide(description: "End time in ISO 8601 format (for timeDifference)")
    var endTime: String?
    
    /// Duration in seconds (for formatDuration)
    @Guide(description: "Duration in seconds (for formatDuration)")
    var duration: Double?
    
    /// Time zone identifier (e.g., "America/New_York")
    @Guide(description: "Time zone identifier (e.g., 'America/New_York')")
    var timeZone: String?
  }
  
  private let dateFormatter = ISO8601DateFormatter()
  
  func call(arguments: Arguments) async throws -> ToolOutput {
    switch arguments.action.lowercased() {
    case "currenttime":
      return getCurrentTime(timeZone: arguments.timeZone)
    case "timedifference":
      return calculateTimeDifference(arguments: arguments)
    case "formatduration":
      return formatDuration(arguments: arguments)
    default:
      return createErrorOutput(error: TimerError.invalidAction)
    }
  }
  
  private func getCurrentTime(timeZone: String?) -> ToolOutput {
    let now = Date()
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .medium
    
    if let tzIdentifier = timeZone,
       let tz = TimeZone(identifier: tzIdentifier) {
      formatter.timeZone = tz
    }
    
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "success",
        "currentTime": dateFormatter.string(from: now),
        "formattedTime": formatter.string(from: now),
        "timeZone": timeZone ?? TimeZone.current.identifier,
        "timestamp": now.timeIntervalSince1970
      ])
    )
  }
  
  private func calculateTimeDifference(arguments: Arguments) -> ToolOutput {
    guard let startTimeString = arguments.startTime,
          let endTimeString = arguments.endTime,
          let startDate = dateFormatter.date(from: startTimeString),
          let endDate = dateFormatter.date(from: endTimeString) else {
      return createErrorOutput(error: TimerError.invalidDateFormat)
    }
    
    let difference = endDate.timeIntervalSince(startDate)
    let absoluteDifference = abs(difference)
    
    let hours = Int(absoluteDifference) / 3600
    let minutes = (Int(absoluteDifference) % 3600) / 60
    let seconds = Int(absoluteDifference) % 60
    
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "success",
        "startTime": startTimeString,
        "endTime": endTimeString,
        "differenceInSeconds": difference,
        "absoluteDifferenceInSeconds": absoluteDifference,
        "hours": hours,
        "minutes": minutes,
        "seconds": seconds,
        "formattedDifference": String(format: "%02d:%02d:%02d", hours, minutes, seconds),
        "isEndAfterStart": difference > 0
      ])
    )
  }
  
  private func formatDuration(arguments: Arguments) -> ToolOutput {
    guard let duration = arguments.duration else {
      return createErrorOutput(error: TimerError.missingDuration)
    }
    
    let absoluteDuration = abs(duration)
    let days = Int(absoluteDuration) / 86400
    let hours = (Int(absoluteDuration) % 86400) / 3600
    let minutes = (Int(absoluteDuration) % 3600) / 60
    let seconds = Int(absoluteDuration) % 60
    
    var components: [String] = []
    if days > 0 { components.append("\(days) day\(days == 1 ? "" : "s")") }
    if hours > 0 { components.append("\(hours) hour\(hours == 1 ? "" : "s")") }
    if minutes > 0 { components.append("\(minutes) minute\(minutes == 1 ? "" : "s")") }
    if seconds > 0 || components.isEmpty { components.append("\(seconds) second\(seconds == 1 ? "" : "s")") }
    
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "success",
        "durationInSeconds": duration,
        "days": days,
        "hours": hours,
        "minutes": minutes,
        "seconds": seconds,
        "formattedDuration": components.joined(separator: ", "),
        "shortFormat": String(format: "%02d:%02d:%02d", hours + (days * 24), minutes, seconds)
      ])
    )
  }
  
  private func createErrorOutput(error: Error) -> ToolOutput {
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "error",
        "error": error.localizedDescription,
        "message": "Failed to perform timer operation"
      ])
    )
  }
}

enum TimerError: Error, LocalizedError {
  case invalidAction
  case invalidDateFormat
  case missingDuration
  
  var errorDescription: String? {
    switch self {
    case .invalidAction:
      return "Invalid action. Use 'currentTime', 'timeDifference', or 'formatDuration'."
    case .invalidDateFormat:
      return "Invalid date format. Please use ISO 8601 format (e.g., '2025-06-17T14:30:00Z')."
    case .missingDuration:
      return "Duration is required for formatting."
    }
  }
}