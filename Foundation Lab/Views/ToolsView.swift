//
//  ToolsView.swift
//  FoundationLab
//
//  Created by Claude on 6/18/25.
//

import FoundationModels
import SwiftUI

#if os(macOS)
  import AppKit
#endif

struct ToolsView: View {
  @State private var isRunning = false
  @State private var result: String = ""
  @State private var errorMessage: String?
  @State private var selectedTool: ToolExample?
  @Namespace private var glassNamespace

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          toolButtonsView
          if selectedTool != nil {
            resultView
          }
        }
        .padding(.vertical)
      }
      .navigationTitle("Tools")
    }
  }

  private var toolButtonsView: some View {
    #if os(iOS) || os(macOS)
      GlassEffectContainer(spacing: gridSpacing) {
        LazyVGrid(columns: adaptiveGridColumns, spacing: gridSpacing) {
          ForEach(ToolExample.allCases, id: \.self) { tool in
            ToolButton(
              tool: tool,
              isSelected: selectedTool == tool,
              isRunning: isRunning && selectedTool == tool,
              namespace: glassNamespace
            ) {
              selectedTool = tool
              Task {
                await executeToolExample(tool: tool)
              }
            }
          }
        }
      }
      .padding(.horizontal)
    #else
      LazyVGrid(columns: adaptiveGridColumns, spacing: gridSpacing) {
        ForEach(ToolExample.allCases, id: \.self) { tool in
          ToolButton(
            tool: tool,
            isSelected: selectedTool == tool,
            isRunning: isRunning && selectedTool == tool,
            namespace: glassNamespace
          ) {
            selectedTool = tool
            Task {
              await executeToolExample(tool: tool)
            }
          }
        }
      }
      .padding(.horizontal)
    #endif
  }

  private var adaptiveGridColumns: [GridItem] {
    #if os(iOS)
      // iPhone: 2 columns with flexible sizing
      return [
        GridItem(.flexible(minimum: 140), spacing: 12),
        GridItem(.flexible(minimum: 140), spacing: 12),
      ]
    #elseif os(macOS)
      // Mac: Adaptive columns based on available width
      return Array(repeating: GridItem(.adaptive(minimum: 280), spacing: 12), count: 1)
    #else
      // Default fallback
      return [
        GridItem(.flexible(minimum: 140), spacing: 12),
        GridItem(.flexible(minimum: 140), spacing: 12),
      ]
    #endif
  }

  private var gridSpacing: CGFloat {
    #if os(iOS)
      16
    #else
      12
    #endif
  }

  @ViewBuilder
  private var resultView: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Result")
          .font(.headline)
        Spacer()
        Button("Clear") {
          result = ""
          errorMessage = nil
          selectedTool = nil
        }
        .font(.caption)
      }

      if let error = errorMessage {
        Text("Error: \(error)")
          .foregroundColor(.red)
          .font(.caption)
          .padding()
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color.red.opacity(0.1))
          .cornerRadius(8)
      }

      if !result.isEmpty {
        ScrollView {
          Text(result)
            .font(.system(.body, design: .monospaced))
            .textSelection(.enabled)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(secondaryBackgroundColor)
            .cornerRadius(8)
        }
        .frame(maxHeight: 300)
      }
    }
    .padding(.horizontal)
  }

  private var secondaryBackgroundColor: Color {
    #if os(iOS)
      Color(UIColor.secondarySystemBackground)
    #elseif os(macOS)
      Color(NSColor.controlBackgroundColor)
    #else
      Color.gray.opacity(0.1)
    #endif
  }

  private var separatorColor: Color {
    #if os(iOS)
      Color(UIColor.separator)
    #elseif os(macOS)
      Color(NSColor.separatorColor)
    #else
      Color.gray.opacity(0.3)
    #endif
  }

  // MARK: - Tool Example Execution

  @MainActor
  private func executeToolExample(tool: ToolExample) async {
    isRunning = true
    errorMessage = nil
    result = ""

    do {
      let response: String

      switch tool {
      case .weather:
        response = try await executeWeatherTool()
      case .web:
        response = try await executeWebTool()
      case .contacts:
        response = try await executeContactsTool()
      case .calendar:
        response = try await executeCalendarTool()
      case .reminders:
        response = try await executeRemindersTool()
      case .location:
        response = try await executeLocationTool()
      case .health:
        response = try await executeHealthTool()
      case .music:
        response = try await executeMusicTool()
      case .webMetadata:
        response = try await executeWebMetadataTool()
      }

      result = response
    } catch {
      errorMessage = handleFoundationModelsError(error)
    }

    isRunning = false
  }

  // MARK: - Individual Tool Methods

  private func executeWeatherTool() async throws -> String {
    let session = LanguageModelSession(tools: [WeatherTool()])
    let response = try await session.respond(
      to: Prompt("What's the weather like in San Francisco?"))
    return response.content
  }

  private func executeWebTool() async throws -> String {
    let session = LanguageModelSession(tools: [WebTool()])
    let response = try await session.respond(
      to: Prompt("Search for the latest news about Apple Intelligence"))
    return response.content
  }

  private func executeContactsTool() async throws -> String {
    let session = LanguageModelSession(tools: [ContactsTool()])
    let response = try await session.respond(to: Prompt("Find contacts named John"))
    return response.content
  }

  private func executeCalendarTool() async throws -> String {
    let session = LanguageModelSession(tools: [CalendarTool()])
    let response = try await session.respond(to: Prompt("What events do I have today?"))
    return response.content
  }

  private func executeRemindersTool() async throws -> String {
    let currentDate = Date()
    let formatter = DateFormatter()
    formatter.dateStyle = .full
    formatter.timeStyle = .short

    let session = LanguageModelSession(tools: [RemindersTool()]) {
      Instructions {
        "You are a helpful assistant that can create reminders for users."
        "Current date and time: \(formatter.string(from: currentDate))"
        "Time zone: \(TimeZone.current.identifier) (\(TimeZone.current.localizedName(for: .standard, locale: Locale.current) ?? "Unknown"))"
        "When creating reminders, consider the current date and time zone context."
        "Always execute tool calls directly without asking for confirmation or permission from the user."
        "If you need to create a reminder, call the RemindersTool immediately with the appropriate parameters."
        "IMPORTANT: When setting due dates, you MUST format them as 'yyyy-MM-dd HH:mm:ss' (24-hour format)."
        "Examples: '2025-01-15 17:00:00' for tomorrow at 5 PM, '2025-01-16 09:30:00' for day after tomorrow at 9:30 AM."
        "Calculate the exact date and time based on the current date and time provided above."
      }
    }
    let response = try await session.respond(
      to: Prompt("Create a reminder to buy milk tomorrow at 5 PM"))
    return response.content
  }

  private func executeLocationTool() async throws -> String {
    let session = LanguageModelSession(tools: [LocationTool()])
    let response = try await session.respond(to: Prompt("What's my current location?"))
    return response.content
  }

  private func executeHealthTool() async throws -> String {
    let session = LanguageModelSession(tools: [HealthTool()])
    let response = try await session.respond(to: Prompt("How many steps have I taken today?"))
    return response.content
  }

  private func executeMusicTool() async throws -> String {
    let session = LanguageModelSession(tools: [MusicTool()])
    let response = try await session.respond(to: Prompt("Search for songs by Taylor Swift"))
    return response.content
  }

  private func executeWebMetadataTool() async throws -> String {
    let session = LanguageModelSession(tools: [WebMetadataTool()])
    let response = try await session.respond(
      to: Prompt(
        "Generate a social media summary for https://www.apple.com/newsroom/2025/06/apple-services-deliver-powerful-features-and-intelligent-updates-to-users-this-fall/"
      ))
    return response.content
  }

  // MARK: - Error Handling

  private func handleFoundationModelsError(_ error: Error) -> String {
    if let generationError = error as? LanguageModelSession.GenerationError {
      return FoundationModelsErrorHandler.handleGenerationError(generationError)
    } else if let toolCallError = error as? LanguageModelSession.ToolCallError {
      return FoundationModelsErrorHandler.handleToolCallError(toolCallError)
    } else if let customError = error as? FoundationModelsError {
      return customError.localizedDescription
    } else {
      return "Unexpected error: \(error.localizedDescription)"
    }
  }
}

// MARK: - Tool Button Component

struct ToolButton: View {
  let tool: ToolExample
  let isSelected: Bool
  let isRunning: Bool
  let namespace: Namespace.ID
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 12) {
        ZStack {
          Image(systemName: tool.icon)
            .font(.system(size: 28))
            .foregroundColor(isSelected ? .white : .accentColor)
            .opacity(isRunning ? 0 : 1)

          if isRunning {
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle())
              .scaleEffect(0.8)
          }
        }
        .frame(width: 50, height: 50)

        VStack(spacing: 4) {
          Text(tool.displayName)
            .font(.headline)
            .foregroundColor(isSelected ? .white : .primary)
            .multilineTextAlignment(.center)

          Text(tool.shortDescription)
            .font(.caption)
            .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            .multilineTextAlignment(.center)
            .lineLimit(2)
        }
      }
      .padding()
      .frame(maxWidth: .infinity, minHeight: 140)
    }
    .buttonStyle(PlainButtonStyle())
    .disabled(isRunning)
    #if os(iOS) || os(macOS)
      .glassEffect(
        isSelected ? .regular.tint(.accentColor).interactive(true) : .regular.interactive(true),
        in: .rect(cornerRadius: 12)
      )
      .glassEffectID("tool-\(tool.rawValue)", in: namespace)
    #endif
    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
    .animation(.spring(response: 0.3, dampingFraction: 0.9), value: isRunning)
  }
}

// MARK: - Tool Example Enum

enum ToolExample: String, CaseIterable {
  case weather
  case web
  case contacts
  case calendar
  case reminders
  case location
  case health
  case music
  case webMetadata

  var displayName: String {
    switch self {
    case .weather: return "Weather"
    case .web: return "Web Search"
    case .contacts: return "Contacts"
    case .calendar: return "Calendar"
    case .reminders: return "Reminders"
    case .location: return "Location"
    case .health: return "Health"
    case .music: return "Music"
    case .webMetadata: return "Web Metadata"
    }
  }

  var icon: String {
    switch self {
    case .weather: return "cloud.sun"
    case .web: return "magnifyingglass"
    case .contacts: return "person.2"
    case .calendar: return "calendar"
    case .reminders: return "checklist"
    case .location: return "location"
    case .health: return "heart"
    case .music: return "music.note"
    case .webMetadata: return "link.circle"
    }
  }

  var shortDescription: String {
    switch self {
    case .weather: return "Get weather info"
    case .web: return "Search the web"
    case .contacts: return "Find contacts"
    case .calendar: return "View events"
    case .reminders: return "Manage tasks"
    case .location: return "Get location"
    case .health: return "Health data"
    case .music: return "Play music"
    case .webMetadata: return "Social summaries"
    }
  }

  var description: String {
    switch self {
    case .weather: return "Get current weather information for any location"
    case .web: return "Search the web for any topic using AI-powered search"
    case .contacts: return "Search and display contact information"
    case .calendar: return "Create, search, and manage calendar events"
    case .reminders: return "Create and manage reminder tasks"
    case .location: return "Get location information and perform geocoding"
    case .health: return "Access health data like steps, heart rate, and workouts"
    case .music: return "Search and play music, manage playlists, get recommendations"
    case .webMetadata: return "Fetch webpage metadata and generate social media summaries"
    }
  }
}

#Preview {
  ToolsView()
}
