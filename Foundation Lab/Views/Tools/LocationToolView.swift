//
//  LocationToolView.swift
//  FoundationLab
//
//  Created by Claude on 1/14/25.
//

import FoundationModels
import SwiftUI

struct LocationToolView: View {
  @Environment(ToolExecutor.self) private var executor

  var body: some View {
    ToolViewBase(
      title: "Location",
      icon: "location",
      description: "Get location information and perform geocoding",
      isRunning: executor.isRunning,
      errorMessage: executor.errorMessage
    ) {
      VStack(alignment: .leading, spacing: 16) {
        if let successMessage = executor.successMessage {
          SuccessBanner(message: successMessage)
        }

        Button(action: getCurrentLocation) {
          HStack {
            if executor.isRunning {
              ProgressView()
                .scaleEffect(0.8)
                .foregroundColor(.white)
                .accessibilityLabel("Processing")
            } else {
              Image(systemName: "location")
                .accessibilityHidden(true)
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
        .disabled(executor.isRunning)
        .accessibilityLabel("Get current location")
        .accessibilityHint(
          executor.isRunning ? "Processing request" : "Tap to get your current location")

        if !executor.result.isEmpty {
          ResultDisplay(result: executor.result, isSuccess: executor.errorMessage == nil)
        }
      }
    }
  }

  private func getCurrentLocation() {
    Task {
      await executor.execute(
        tool: LocationTool(),
        prompt: "What's my current location?",
        successMessage: "Location retrieved successfully!"
      )
    }
  }
}

#Preview {
  NavigationStack {
    LocationToolView()
      .withToolExecutor()
  }
}
