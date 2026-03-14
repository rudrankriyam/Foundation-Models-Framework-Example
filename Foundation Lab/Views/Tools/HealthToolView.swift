//
//  HealthToolView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import FoundationLabCore
import SwiftUI

struct HealthToolView: View {
    @State private var executor = ToolExecutor()
    @State private var query: String = "How many steps have I taken today?"

    var body: some View {
        ToolViewBase(
            title: "Health",
            icon: "heart",
            description: "Access health data like steps, heart rate, and workouts",
            isRunning: executor.isRunning,
            errorMessage: executor.errorMessage
        ) {
            VStack(alignment: .leading, spacing: Spacing.large) {
                if let successMessage = executor.successMessage {
                    SuccessBanner(message: successMessage)
                }

                ToolInputField(
                    label: "HEALTH QUERY",
                    text: $query,
                    placeholder: "How many steps have I taken today?"
                )

                ToolExecuteButton(
                    "Query Health Data",
                    systemImage: "heart",
                    isRunning: executor.isRunning,
                    action: executeHealthQuery
                )
                .disabled(executor.isRunning || query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if !executor.result.isEmpty {
                    ResultDisplay(result: executor.result, isSuccess: executor.errorMessage == nil)
                }
            }
        }
    }

    private func executeHealthQuery() {
        Task {
            await executor.executeCapability(
                successMessage: "Health data query completed successfully!"
            ) {
                try await QueryHealthDataUseCase().execute(
                    QueryHealthDataRequest(
                        query: query,
                        referenceDate: .now,
                        timeZoneIdentifier: TimeZone.current.identifier,
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
        HealthToolView()
    }
}
