//
//  ShortcutsTool.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/17/25.
//

import Foundation
import FoundationModels
import AppIntents

/// `ShortcutsTool` provides the ability to run Shortcuts app shortcuts.
///
/// This tool can list available shortcuts and run them with parameters.
/// It integrates with the Shortcuts app to execute user-created automations.
@available(iOS 16.0, macOS 13.0, *)
struct ShortcutsTool: Tool {
  
  /// The name of the tool, used for identification.
  let name = "runShortcuts"
  /// A brief description of the tool's functionality.
  let description = "List and run shortcuts from the Shortcuts app with optional parameters"
  
  /// Arguments for shortcuts operations.
  @Generable
  struct Arguments {
    /// The action to perform: "list" or "run"
    @Guide(description: "The action to perform: 'list' or 'run'")
    var action: String
    
    /// Name of the shortcut to run
    @Guide(description: "Name of the shortcut to run")
    var shortcutName: String?
    
    /// Input text to pass to the shortcut
    @Guide(description: "Input text to pass to the shortcut")
    var input: String?
    
    /// Additional parameters as comma-separated key:value pairs
    @Guide(description: "Additional parameters as comma-separated key:value pairs (e.g., 'name:John,age:30')")
    var parameters: String?
  }
  
  /// Shortcut data structure
  struct ShortcutData: Encodable {
    let name: String
    let id: String?
    let description: String?
  }
  
  func call(arguments: Arguments) async throws -> ToolOutput {
    switch arguments.action.lowercased() {
    case "list":
      return await listShortcuts()
    case "run":
      return try await runShortcut(arguments: arguments)
    default:
      return createErrorOutput(error: ShortcutsError.invalidAction)
    }
  }
  
  private func listShortcuts() async -> ToolOutput {
    // Note: In a real implementation, you would use the Shortcuts framework
    // to fetch available shortcuts. This is a simplified version.
    
    // For demo purposes, we'll return common shortcut categories
    let commonShortcuts = [
      ShortcutData(
        name: "Message Someone",
        id: "com.apple.shortcuts.message",
        description: "Send a message to a contact"
      ),
      ShortcutData(
        name: "Play Music",
        id: "com.apple.shortcuts.playmusic",
        description: "Play music from your library"
      ),
      ShortcutData(
        name: "Get Directions",
        id: "com.apple.shortcuts.directions",
        description: "Get directions to a location"
      ),
      ShortcutData(
        name: "Create Note",
        id: "com.apple.shortcuts.note",
        description: "Create a new note"
      ),
      ShortcutData(
        name: "Set Timer",
        id: "com.apple.shortcuts.timer",
        description: "Set a timer for a specified duration"
      )
    ]
    
    return createShortcutsSuccessOutput(
      message: "Available shortcuts (sample list)",
      shortcuts: commonShortcuts
    )
  }
  
  private func runShortcut(arguments: Arguments) async throws -> ToolOutput {
    guard let shortcutName = arguments.shortcutName else {
      return createErrorOutput(error: ShortcutsError.missingShortcutName)
    }
    
    // Parse parameters if provided
    var parsedParameters: [String: String] = [:]
    if let parametersString = arguments.parameters {
      let pairs = parametersString.split(separator: ",")
      for pair in pairs {
        let keyValue = pair.split(separator: ":")
        if keyValue.count == 2 {
          let key = String(keyValue[0]).trimmingCharacters(in: .whitespaces)
          let value = String(keyValue[1]).trimmingCharacters(in: .whitespaces)
          parsedParameters[key] = value
        }
      }
    }
    
    // Note: In a real implementation, you would use the following approach:
    // 1. Use WFRunShortcutAction or similar API to execute the shortcut
    // 2. Pass the input and parameters to the shortcut
    // 3. Retrieve the output from the shortcut
    
    // For demonstration, we'll simulate running a shortcut
    let simulatedResult = simulateShortcutRun(
      name: shortcutName,
      input: arguments.input,
      parameters: parsedParameters
    )
    
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "success",
        "message": "Shortcut executed successfully",
        "shortcutName": shortcutName,
        "input": arguments.input ?? "",
        "parameters": parsedParameters,
        "result": simulatedResult
      ])
    )
  }
  
  private func simulateShortcutRun(name: String, input: String?, parameters: [String: String]) -> String {
    // Simulate different shortcut behaviors based on name
    switch name.lowercased() {
    case "message someone":
      let recipient = parameters["recipient"] ?? "contact"
      let message = input ?? "Hello!"
      return "Message '\(message)' prepared for \(recipient)"
      
    case "play music":
      let playlist = parameters["playlist"] ?? "favorites"
      return "Playing \(playlist) playlist"
      
    case "get directions":
      let destination = input ?? parameters["destination"] ?? "home"
      return "Getting directions to \(destination)"
      
    case "create note":
      let title = parameters["title"] ?? "New Note"
      let content = input ?? "Note content"
      return "Note '\(title)' created with content: \(content)"
      
    case "set timer":
      let duration = parameters["duration"] ?? input ?? "5 minutes"
      return "Timer set for \(duration)"
      
    default:
      return "Shortcut '\(name)' executed with input: \(input ?? "none")"
    }
  }
  
  private func createShortcutsSuccessOutput(message: String, shortcuts: [ShortcutData]) -> ToolOutput {
    var properties: [String: Any] = [
      "status": "success",
      "message": message,
      "count": shortcuts.count
    ]
    
    properties["shortcuts"] = shortcuts.map { shortcut in
      var shortcutDict: [String: Any] = [
        "name": shortcut.name
      ]
      
      if let id = shortcut.id {
        shortcutDict["id"] = id
      }
      
      if let description = shortcut.description {
        shortcutDict["description"] = description
      }
      
      return shortcutDict
    }
    
    return ToolOutput(GeneratedContent(properties: properties))
  }
  
  private func createErrorOutput(error: Error) -> ToolOutput {
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "error",
        "error": error.localizedDescription,
        "message": "Failed to perform shortcuts operation"
      ])
    )
  }
}

enum ShortcutsError: Error, LocalizedError {
  case invalidAction
  case missingShortcutName
  case shortcutNotFound
  case executionFailed
  
  var errorDescription: String? {
    switch self {
    case .invalidAction:
      return "Invalid action. Use 'list' or 'run'."
    case .missingShortcutName:
      return "Shortcut name is required for running a shortcut."
    case .shortcutNotFound:
      return "Shortcut not found with the provided name."
    case .executionFailed:
      return "Failed to execute the shortcut."
    }
  }
}