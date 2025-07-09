//
//  HealthToolView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import FoundationModels
import FoundationModelsTools
import SwiftUI

struct HealthToolView: View {
  @Environment(ToolExecutor.self) private var executor
  @State private var query: String = "How many steps have I taken today?"

  var body: some View {
    ToolViewBase(
      title: "Health",
      icon: "heart",
      description: "Access health data like steps, heart rate, and workouts",
      isRunning: executor.isRunning,
      errorMessage: executor.errorMessage
    ) {
      VStack(alignment: .leading, spacing: Spacing.large) {
        if let successMessage = executor.successMessage {
          SuccessBanner(message: successMessage)
        }

        VStack(alignment: .leading, spacing: 8) {
          Text("HEALTH QUERY")
            .font(.footnote)
            .fontWeight(.medium)
            .foregroundColor(.secondary)

          TextEditor(text: $query)
            .scrollContentBackground(.hidden)
            .padding(Spacing.medium)
            .frame(height: 50)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }

        Button(action: executeHealthQuery) {
          HStack(spacing: Spacing.small) {
            if executor.isRunning {
              ProgressView()
                .scaleEffect(0.8)
                .accessibilityLabel("Processing")
            } else {
              Image(systemName: "heart")
                .accessibilityHidden(true)
            }

            Text(executor.isRunning ? "Querying..." : "Query Health Data")
              .fontWeight(.medium)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, Spacing.small)
        }
        .buttonStyle(.glassProminent)
        .disabled(executor.isRunning || query.isEmpty)
        .accessibilityLabel("Query health data")
        .accessibilityHint(executor.isRunning ? "Processing request" : "Tap to query health data")

        if !executor.result.isEmpty {
          ResultDisplay(result: executor.result, isSuccess: executor.errorMessage == nil)
        }
      }
    }
  }

  private func executeHealthQuery() {
    Task {
      await executor.execute(
        tool: HealthTool(),
        prompt: query,
        successMessage: "Health data query completed successfully!"
      )
    }
  }
}

#Preview {
  NavigationStack {
    HealthToolView()
      .withToolExecutor()
  }
}
