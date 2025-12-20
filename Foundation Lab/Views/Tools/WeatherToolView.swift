//
//  WeatherToolView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import FoundationModels
import FoundationModelsTools
import SwiftUI

struct WeatherToolView: View {
    @State private var executor = ToolExecutor()
    @State private var location: String = "San Francisco"

    var body: some View {
        ToolViewBase(
            title: "Weather",
            icon: "cloud.sun",
            description: "Get current weather information for any location",
            isRunning: executor.isRunning,
            errorMessage: executor.errorMessage
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
                    isRunning: executor.isRunning,
                    action: executeWeatherTool
                )
                .disabled(location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if !executor.result.isEmpty {
                    ResultDisplay(
                        result: executor.result,
                        isSuccess: executor.errorMessage == nil
                    )
                }
            }
        }
    }

    private func executeWeatherTool() {
        Task {
            await executor.execute(
                tool: WeatherTool(),
                prompt: "What's the weather like in \(location)?"
            )
        }
    }
}

#Preview {
    NavigationStack {
        WeatherToolView()
    }
}
