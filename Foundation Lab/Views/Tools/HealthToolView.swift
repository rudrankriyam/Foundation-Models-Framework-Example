//
//  HealthToolView.swift
//  FoundationLab
//
//  Created by Claude on 1/14/25.
//

import FoundationModels
import SwiftUI

struct HealthToolView: View {
  @State private var isRunning = false
  @State private var result: String = ""
  @State private var errorMessage: String?
  @State private var query: String = "How many steps have I taken today?"

  var body: some View {
    ToolViewBase(
      title: "Health",
      icon: "heart",
      description: "Access health data like steps, heart rate, and workouts",
      isRunning: isRunning,
      errorMessage: errorMessage
    ) {
      VStack(alignment: .leading, spacing: 16) {
        VStack(alignment: .leading, spacing: 8) {
          Text("Health Query")
            .font(.subheadline)
            .fontWeight(.medium)

          TextField("Ask about your health data", text: $query)
            .textFieldStyle(RoundedBorderTextFieldStyle())
        }

        Button(action: executeHealthQuery) {
          HStack {
            if isRunning {
              ProgressView()
                .scaleEffect(0.8)
                .foregroundColor(.white)
            } else {
              Image(systemName: "heart")
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
        .disabled(isRunning || query.isEmpty)

        if !result.isEmpty {
          ResultDisplay(result: result, isSuccess: errorMessage == nil)
        }
      }
    }
  }

  private func executeHealthQuery() {
    Task {
      await performHealthQuery()
    }
  }

  @MainActor
  private func performHealthQuery() async {
    isRunning = true
    errorMessage = nil
    result = ""

    do {
      let session = LanguageModelSession(tools: [HealthTool()])
      let response = try await session.respond(to: Prompt(query))
      result = response.content
    } catch {
      errorMessage = "Failed to query health data: \(error.localizedDescription)"
    }

    isRunning = false
  }
}

#Preview {
  NavigationStack {
    HealthToolView()
  }
}
