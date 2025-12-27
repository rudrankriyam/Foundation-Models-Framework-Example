//
//  LocationToolView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import FoundationModels
import FoundationModelsTools
import SwiftUI

struct LocationToolView: View {
  @State private var executor = ToolExecutor()

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

        ToolExecuteButton(
          "Get Current Location",
          systemImage: "location",
          isRunning: executor.isRunning,
          action: getCurrentLocation
        )

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
  }
}
