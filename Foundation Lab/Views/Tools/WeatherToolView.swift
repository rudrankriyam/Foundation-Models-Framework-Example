//
//  WeatherToolView.swift
//  FoundationLab
//
//  Created by Claude on 1/14/25.
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
      VStack(alignment: .leading, spacing: 16) {
        VStack(alignment: .leading, spacing: 8) {
          Text("Location")
            .font(.subheadline)
            .fontWeight(.medium)

          TextField("Enter city name", text: $location)
            .textFieldStyle(RoundedBorderTextFieldStyle())
        }

        Button(action: executeWeatherTool) {
          HStack {
            if isRunning {
              ProgressView()
                .scaleEffect(0.8)
                .foregroundColor(.white)
            } else {
              Image(systemName: "cloud.sun")
            }

            Text("Get Weather")
              .fontWeight(.medium)
          }
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.accentColor)
          .foregroundColor(.white)
          .cornerRadius(12)
        }
        .disabled(isRunning || location.isEmpty)

        if !result.isEmpty {
          ResultDisplay(result: result, isSuccess: errorMessage == nil)
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
