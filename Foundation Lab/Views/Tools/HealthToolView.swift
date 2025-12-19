//
//  HealthToolView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import FoundationModels
import FoundationModelsTools
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

                VStack(alignment: .leading, spacing: 8) {
                    Text("HEALTH QUERY")
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    TextEditor(text: $query)
                        .scrollContentBackground(.hidden)
                        .padding(Spacing.medium)
                        .frame(height: 50)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                }

                Button(action: executeHealthQuery) {
                    HStack(spacing: Spacing.small) {
                        if executor.isRunning {
                            ProgressView()
                                .scaleEffect(0.8)
                                .accessibilityLabel("Processing")
                        } else {
                            Image(systemName: "heart")
                                .accessibilityHidden(true)
                        }

                        Text(executor.isRunning ? "Querying..." : "Query Health Data")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.small)
                }
                .buttonStyle(.glassProminent)
                .disabled(executor.isRunning || query.isEmpty)
                .accessibilityLabel("Query health data")
                .accessibilityHint(executor.isRunning ? "Processing request" : "Tap to query health data")

                if !executor.result.isEmpty {
                    ResultDisplay(result: executor.result, isSuccess: executor.errorMessage == nil)
                }
            }
        }
    }

	    private func executeHealthQuery() {
	        Task {
	            let today = Date()
	            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
	            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: today)!

	            let todayString = today.formatted(.iso8601.year().month().day().dateSeparator(.dash))
	            let yesterdayString = yesterday.formatted(.iso8601.year().month().day().dateSeparator(.dash))
	            let weekAgoString = weekAgo.formatted(.iso8601.year().month().day().dateSeparator(.dash))

	            let prompt = """
	            \(query)

	            Today's date is: \(todayString)

	            Please use the Health tool (`accessHealth`) with the appropriate `dataType`, `startDate`, and `endDate`
	            based on the query above.

	            Important:
	            - Do NOT include an `action` argument (the tool does not support it).
	            - `dataType` must be one of: steps, heartRate, workouts, sleep, activeEnergy, distance.

	            IMPORTANT: Pay attention to time periods in the query:
	            - "today" means use startDate="\(todayString)" and endDate="\(todayString)"
	            - "yesterday" means use startDate="\(yesterdayString)" and endDate="\(yesterdayString)"
	            - "this week" means last 7 days: startDate="\(weekAgoString)" and endDate="\(todayString)"
	            - If no time period specified, default to last 7 days: startDate="\(weekAgoString)" and endDate="\(todayString)"

	            Examples:
	            - steps today: dataType="steps", startDate="\(todayString)", endDate="\(todayString)"
	            - heartRate (last 7 days): dataType="heartRate", startDate="\(weekAgoString)", endDate="\(todayString)"
	            - workouts (last 7 days): dataType="workouts", startDate="\(weekAgoString)", endDate="\(todayString)"
	            - sleep (last 7 days): dataType="sleep", startDate="\(weekAgoString)", endDate="\(todayString)"
	            - activeEnergy (last 7 days): dataType="activeEnergy", startDate="\(weekAgoString)", endDate="\(todayString)"
	            - distance (last 7 days): dataType="distance", startDate="\(weekAgoString)", endDate="\(todayString)"
	            """

	            await executor.execute(
	                tool: HealthTool(),
	                prompt: prompt,
	                successMessage: "Health data query completed successfully!"
	            )
	        }
	    }
}

#Preview {
    NavigationStack {
        HealthToolView()
    }
}
