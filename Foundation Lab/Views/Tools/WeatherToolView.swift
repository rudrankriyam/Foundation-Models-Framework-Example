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
        ToolInputField(
          label: "Location",
          text: $location,
          placeholder: "Enter city name"
        )

        ToolExecuteButton(
          "Get Weather",
          systemImage: "cloud.sun",
          isRunning: isRunning,
          action: executeWeatherTool
        )
        .disabled(location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

        if !result.isEmpty {
          ResultDisplay(
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
