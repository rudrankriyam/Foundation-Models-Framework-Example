//
//  LocationToolView.swift
//  FoundationLab
//
//  Created by Claude on 1/14/25.
//

import FoundationModels
import SwiftUI

struct LocationToolView: View {
  @State private var isRunning = false
  @State private var result: String = ""
  @State private var errorMessage: String?

  var body: some View {
    ToolViewBase(
      title: "Location",
      icon: "location",
      description: "Get location information and perform geocoding",
      isRunning: isRunning,
      errorMessage: errorMessage
    ) {
      VStack(alignment: .leading, spacing: 16) {
        Button(action: getCurrentLocation) {
          HStack {
            if isRunning {
              ProgressView()
                .scaleEffect(0.8)
                .foregroundColor(.white)
            } else {
              Image(systemName: "location")
            }

            Text("Get Current Location")
              .fontWeight(.medium)
          }
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.accentColor)
          .foregroundColor(.white)
          .cornerRadius(12)
        }
        .disabled(isRunning)

        if !result.isEmpty {
          ResultDisplay(result: result, isSuccess: errorMessage == nil)
        }
      }
    }
  }

  private func getCurrentLocation() {
    Task {
      await performLocationRequest()
    }
  }

  @MainActor
  private func performLocationRequest() async {
    isRunning = true
    errorMessage = nil
    result = ""

    do {
      let session = LanguageModelSession(tools: [LocationTool()])
      let response = try await session.respond(to: Prompt("What's my current location?"))
      result = response.content
    } catch {
      errorMessage = "Failed to get location: \(error.localizedDescription)"
    }

    isRunning = false
  }
}

#Preview {
  NavigationStack {
    LocationToolView()
  }
}
