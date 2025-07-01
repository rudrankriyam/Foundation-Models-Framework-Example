//
//  WeatherToolView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import FoundationModels
import SwiftUI

struct WeatherToolView: View {
  @State private var isRunning = false
  @State private var result: String = ""
  @State private var errorMessage: String?
  @State private var location: String = "San Francisco"

  var body: some View {
    ToolViewBase(
      title: "Weather",
      icon: "cloud.sun",
      description: "Get current weather information for any location",
      isRunning: isRunning,
      errorMessage: errorMessage
    ) {
      VStack(alignment: .leading, spacing: Spacing.large) {
        VStack(alignment: .leading, spacing: Spacing.small) {
          Text("LOCATION")
            .font(.footnote)
            .fontWeight(.medium)
            .foregroundColor(.secondary)

          TextEditor(text: $location)
            .font(.body)
            .scrollContentBackground(.hidden)
            .padding(Spacing.medium)
            .frame(height: 50)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }

        Button(action: executeWeatherTool) {
          HStack(spacing: Spacing.small) {
            if isRunning {
              ProgressView()
                .scaleEffect(0.8)
                .tint(.white)
            }
            Text(isRunning ? "Getting Weather..." : "Get Weather")
              .font(.callout)
              .fontWeight(.medium)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, Spacing.small)
        }
        .buttonStyle(.glassProminent)
        .disabled(isRunning || location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

        if !result.isEmpty {
          ExampleResultDisplay(
            result: result,
            isSuccess: errorMessage == nil
          )
        }
      }
    }
  }

  private func executeWeatherTool() {
    Task {
      await performWeatherRequest()
    }
  }

  @MainActor
  private func performWeatherRequest() async {
    isRunning = true
    errorMessage = nil
    result = ""

    do {
      let session = LanguageModelSession(tools: [WeatherTool()])
      let response = try await session.respond(
        to: Prompt("What's the weather like in \(location)?"))
      result = response.content
    } catch {
      errorMessage = "Failed to get weather: \(error.localizedDescription)"
    }

    isRunning = false
  }
}

#Preview {
  NavigationStack {
    WeatherToolView()
  }
}
