//
//  CalendarToolView.swift
//  FoundationLab
//
//  Created by Claude on 1/14/25.
//

import FoundationModels
import SwiftUI

struct CalendarToolView: View {
  @State private var isRunning = false
  @State private var result: String = ""
  @State private var errorMessage: String?
  @State private var query: String = "What events do I have today?"

  var body: some View {
    ToolViewBase(
      title: "Calendar",
      icon: "calendar",
      description: "Create, search, and manage calendar events",
      isRunning: isRunning,
      errorMessage: errorMessage
    ) {
      VStack(alignment: .leading, spacing: 16) {
        VStack(alignment: .leading, spacing: 8) {
          Text("Calendar Query")
            .font(.subheadline)
            .fontWeight(.medium)

          TextField("Ask about your calendar", text: $query)
            .textFieldStyle(RoundedBorderTextFieldStyle())
        }

        Button(action: executeCalendarQuery) {
          HStack {
            if isRunning {
              ProgressView()
                .scaleEffect(0.8)
                .foregroundColor(.white)
            } else {
              Image(systemName: "calendar")
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
        .disabled(isRunning || query.isEmpty)

        if !result.isEmpty {
          ResultDisplay(result: result, isSuccess: errorMessage == nil)
        }
      }
    }
  }

  private func executeCalendarQuery() {
    Task {
      await performCalendarQuery()
    }
  }

  @MainActor
  private func performCalendarQuery() async {
    isRunning = true
    errorMessage = nil
    result = ""

    do {
      let session = LanguageModelSession(tools: [CalendarTool()])
      let response = try await session.respond(to: Prompt(query))
      result = response.content
    } catch {
      errorMessage = "Failed to query calendar: \(error.localizedDescription)"
    }

    isRunning = false
  }
}

#Preview {
  NavigationStack {
    CalendarToolView()
  }
}
