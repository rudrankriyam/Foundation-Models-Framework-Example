//
//  HealthToolView.swift
//  FoundationLab
//
//  Created by Claude on 1/14/25.
//

import FoundationModels
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
      VStack(alignment: .leading, spacing: 16) {
        if let successMessage = executor.successMessage {
          SuccessBanner(message: successMessage)
        }

        VStack(alignment: .leading, spacing: 8) {
          Text("Health Query")
            .font(.subheadline)
            .fontWeight(.medium)

          TextField("Ask about your health data", text: $query)
            .textFieldStyle(RoundedBorderTextFieldStyle())
        }

        Button(action: executeHealthQuery) {
          HStack {
            if executor.isRunning {
              ProgressView()
                .scaleEffect(0.8)
                .foregroundColor(.white)
                .accessibilityLabel("Processing")
            } else {
              Image(systemName: "heart")
                .accessibilityHidden(true)
            }

            Text("Query Health Data")
              .fontWeight(.medium)
          }
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.accentColor)
          .foregroundColor(.white)
          .cornerRadius(12)
        }
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
