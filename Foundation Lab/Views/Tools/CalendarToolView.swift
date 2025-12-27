//
//  CalendarToolView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import FoundationModels
import FoundationModelsTools
import SwiftUI

struct CalendarToolView: View {
  @State private var executor = ToolExecutor()
  @State private var query: String = "What events do I have today?"

  var body: some View {
    ToolViewBase(
      title: "Calendar",
      icon: "calendar",
      description: "Create, search, and manage calendar events",
      isRunning: executor.isRunning,
      errorMessage: executor.errorMessage
    ) {
      VStack(alignment: .leading, spacing: Spacing.large) {
        if let successMessage = executor.successMessage {
          SuccessBanner(message: successMessage)
        }

        ToolInputField(
          label: "CALENDAR QUERY",
          text: $query,
          placeholder: "What events do I have today?"
        )

        ToolExecuteButton(
          "Query Calendar",
          systemImage: "calendar",
          isRunning: executor.isRunning,
          action: executeCalendarQuery
        )
        .disabled(executor.isRunning || query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

        if !executor.result.isEmpty {
          ResultDisplay(result: executor.result, isSuccess: executor.errorMessage == nil)
        }
      }
    }
  }

  private func executeCalendarQuery() {
    Task {
      await executor.executeWithPromptBuilder(
        tool: CalendarTool(),
        successMessage: "Calendar query completed successfully!"
      ) {
        """
The user's current time zone is \(TimeZone.current.identifier).
The user's current locale identifier is \(Locale.current.identifier).
The current local date and time is \(formattedCurrentDate()).
Use this information when interpreting relative dates like "today" or "tomorrow".
"""
        query
      }
    }
  }

  private func formattedCurrentDate() -> String {
    let formatter = Date.ISO8601FormatStyle(includingFractionalSeconds: false, timeZone: TimeZone.current)
    return Date.now.formatted(formatter)
  }
}

#Preview {
  NavigationStack {
    CalendarToolView()
  }
}
