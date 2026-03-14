//
//  LocationToolView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import FoundationLabCore
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
      await executor.executeCapability(
        successMessage: "Location retrieved successfully!"
      ) {
        try await GetCurrentLocationUseCase().execute(
          GetCurrentLocationRequest(
            context: CapabilityInvocationContext(
              source: .app,
              localeIdentifier: Locale.current.identifier
            )
          )
        )
      }
    }
  }
}

#Preview {
  NavigationStack {
    LocationToolView()
  }
}
