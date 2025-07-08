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
      VStack(alignment: .leading, spacing: Spacing.large) {
        if let successMessage = executor.successMessage {
          SuccessBanner(message: successMessage)
        }

        VStack(alignment: .leading, spacing: Spacing.small) {
          Text("CALENDAR QUERY")
            .font(.footnote)
            .fontWeight(.medium)
            .foregroundColor(.secondary)

          TextEditor(text: $query)
            .font(.body)
            .scrollContentBackground(.hidden)
            .padding(Spacing.medium)
            .frame(height: 50)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }

        Button(action: executeCalendarQuery) {
          HStack(spacing: Spacing.small) {
            if executor.isRunning {
              ProgressView()
                .scaleEffect(0.8)
                .tint(.white)
            }
            Text(executor.isRunning ? "Querying Calendar..." : "Query Calendar")
              .font(.callout)
              .fontWeight(.medium)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, Spacing.small)
        }
        .buttonStyle(.glassProminent)
        .disabled(executor.isRunning || query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

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
