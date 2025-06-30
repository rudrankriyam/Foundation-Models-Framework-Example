//
//  CalendarToolView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import FoundationModels
import SwiftUI

struct CalendarToolView: View {
  @Environment(ToolExecutor.self) private var executor
  @State private var query: String = "What events do I have today?"

  var body: some View {
    ToolViewBase(
      title: "Calendar",
      icon: "calendar",
      description: "Create, search, and manage calendar events",
      isRunning: executor.isRunning,
      errorMessage: executor.errorMessage
    ) {
      VStack(alignment: .leading, spacing: 16) {
        if let successMessage = executor.successMessage {
          SuccessBanner(message: successMessage)
        }

        VStack(alignment: .leading, spacing: 8) {
          Text("Calendar Query")
            .font(.subheadline)
            .fontWeight(.medium)

          TextField("Ask about your calendar", text: $query)
            .textFieldStyle(RoundedBorderTextFieldStyle())
        }

        Button(action: executeCalendarQuery) {
          HStack {
            if executor.isRunning {
              ProgressView()
                .scaleEffect(0.8)
                .foregroundColor(.white)
                .accessibilityLabel("Processing")
            } else {
              Image(systemName: "calendar")
                .accessibilityHidden(true)
            }

            Text("Query Calendar")
              .fontWeight(.medium)
          }
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.accentColor)
          .foregroundColor(.white)
          .cornerRadius(12)
        }
        .disabled(executor.isRunning || query.isEmpty)
        .accessibilityLabel("Query calendar events")
        .accessibilityHint(executor.isRunning ? "Processing request" : "Tap to search calendar")

        if !executor.result.isEmpty {
          ResultDisplay(result: executor.result, isSuccess: executor.errorMessage == nil)
        }
      }
    }
  }

  private func executeCalendarQuery() {
    Task {
      await executor.execute(
        tool: CalendarTool(),
        prompt: query,
        successMessage: "Calendar query completed successfully!"
      )
    }
  }
}

#Preview {
  NavigationStack {
    CalendarToolView()
      .withToolExecutor()
  }
}
