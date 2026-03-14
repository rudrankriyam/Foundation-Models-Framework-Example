//
//  CalendarToolView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import FoundationLabCore
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
      await executor.executeCapability(
        successMessage: "Calendar query completed successfully!"
      ) {
        try await QueryCalendarUseCase().execute(
          QueryCalendarRequest(
            query: query,
            referenceDate: .now,
            timeZoneIdentifier: TimeZone.current.identifier,
            context: CapabilityInvocationContext(
              source: .app,
              localeIdentifier: Locale.current.identifier
            )
          )
        )
      }
    }
  }
}

#Preview {
  NavigationStack {
    CalendarToolView()
  }
}
