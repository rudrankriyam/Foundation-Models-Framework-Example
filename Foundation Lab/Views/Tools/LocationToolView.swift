//
//  LocationToolView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
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
      VStack(alignment: .leading, spacing: Spacing.large) {
        if let successMessage = executor.successMessage {
          SuccessBanner(message: successMessage)
        }

        Button(action: getCurrentLocation) {
          HStack(spacing: Spacing.small) {
            if executor.isRunning {
              ProgressView()
                .scaleEffect(0.8)
                .tint(.white)
            }
            Text(executor.isRunning ? "Getting Location..." : "Get Current Location")
              .font(.callout)
              .fontWeight(.medium)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, Spacing.small)
        }
        .buttonStyle(.glassProminent)
        .disabled(executor.isRunning)

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
