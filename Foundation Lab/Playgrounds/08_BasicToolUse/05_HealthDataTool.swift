//
//  05_HealthDataTool.swift
//  Exploring Foundation Models
//
//  Created by Rudrank Riyam on 9/24/25.
//

import Foundation
import FoundationModels
import Playgrounds

struct HealthDataTool: Tool {
    let name = "fetchHealthData"
    let description = "Fetch current health data including steps, heart rate, sleep, and other metrics"

    @Generable
    struct Arguments {
        @Guide(description: "The type of health data to fetch: 'today', 'weekly', or specific metric like 'steps', 'heartRate', 'sleep', 'activeEnergy', 'distance'")
        var dataType: String
    }

    @Generable
    struct HealthMetrics {
        let dataType: String
        let steps: Int?
        let activeEnergy: Int?
        let distance: Double?
        let heartRate: Int?
        let sleep: Double?
        let date: String
        let status: String
    }

    func call(arguments: Arguments) async throws -> HealthMetrics {
        let dataType = arguments.dataType.lowercased()

        switch dataType {
        case "today":
            return generateTodayData()
        case "weekly":
            return generateWeeklyData()
        case "steps":
            return generateSpecificMetric(type: "steps")
        case "heartrate", "heart_rate":
            return generateSpecificMetric(type: "heartRate")
        case "sleep":
            return generateSpecificMetric(type: "sleep")
        case "activeenergy", "active_energy":
            return generateSpecificMetric(type: "activeEnergy")
        case "distance":
            return generateSpecificMetric(type: "distance")
        default:
            throw HealthDataError.invalidDataType(dataType)
        }
    }

    private func generateTodayData() -> HealthMetrics {
        // In a real implementation, this would fetch from HealthKit
        return HealthMetrics(
            dataType: "today",
            steps: Int.random(in: 5000...15000),
            activeEnergy: Int.random(in: 200...800),
            distance: Double.random(in: 3.0...12.0),
            heartRate: Int.random(in: 60...100),
            sleep: Double.random(in: 6.0...9.0),
            date: DateFormatter.todayString,
            status: "success"
        )
    }

    private func generateWeeklyData() -> HealthMetrics {
        // Generate weekly summary data
        return HealthMetrics(
            dataType: "weekly",
            steps: Int.random(in: 35000...70000),
            activeEnergy: Int.random(in: 1500...3500),
            distance: Double.random(in: 20.0...50.0),
            heartRate: Int.random(in: 65...85),
            sleep: Double.random(in: 6.5...8.5),
            date: "Last 7 days",
            status: "success"
        )
    }

    private func generateSpecificMetric(type: String) -> HealthMetrics {
        switch type {
        case "steps":
            return HealthMetrics(
                dataType: type,
                steps: Int.random(in: 8000...12000),
                activeEnergy: nil,
                distance: nil,
                heartRate: nil,
                sleep: nil,
                date: DateFormatter.todayString,
                status: "success"
            )
        case "heartRate":
            return HealthMetrics(
                dataType: type,
                steps: nil,
                activeEnergy: nil,
                distance: nil,
                heartRate: Int.random(in: 65...95),
                sleep: nil,
                date: DateFormatter.todayString,
                status: "success"
            )
        case "sleep":
            return HealthMetrics(
                dataType: type,
                steps: nil,
                activeEnergy: nil,
                distance: nil,
                heartRate: nil,
                sleep: Double.random(in: 6.5...8.5),
                date: DateFormatter.yesterdayString,
                status: "success"
            )
        case "activeEnergy":
            return HealthMetrics(
                dataType: type,
                steps: nil,
                activeEnergy: Int.random(in: 300...600),
                distance: nil,
                heartRate: nil,
                sleep: nil,
                date: DateFormatter.todayString,
                status: "success"
            )
        case "distance":
            return HealthMetrics(
                dataType: type,
                steps: nil,
                activeEnergy: nil,
                distance: Double.random(in: 4.0...10.0),
                heartRate: nil,
                sleep: nil,
                date: DateFormatter.todayString,
                status: "success"
            )
        default:
            return HealthMetrics(
                dataType: type,
                steps: nil,
                activeEnergy: nil,
                distance: nil,
                heartRate: nil,
                sleep: nil,
                date: DateFormatter.todayString,
                status: "error"
            )
        }
    }

    enum HealthDataError: Error, LocalizedError {
        case invalidDataType(String)
        case healthKitUnavailable
        case permissionDenied

        var errorDescription: String? {
            switch self {
            case .invalidDataType(let type):
                return "Invalid data type: '\(type)'. Use 'today', 'weekly', 'steps', 'heartRate', 'sleep', 'activeEnergy', or 'distance'."
            case .healthKitUnavailable:
                return "HealthKit is not available on this device"
            case .permissionDenied:
                return "Permission denied to access health data"
            }
        }
    }
}

extension DateFormatter {
    static var todayString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: Date())
    }

    static var yesterdayString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return formatter.string(from: yesterday)
    }
}

#Playground {
    let healthTool = HealthDataTool()

    let todayArgs = HealthDataTool.Arguments(dataType: "today")
    let todayResult = try await healthTool.call(arguments: todayArgs)
    debugPrint("Today's health data: \(todayResult)")

    let stepsArgs = HealthDataTool.Arguments(dataType: "steps")
    let stepsResult = try await healthTool.call(arguments: stepsArgs)
    debugPrint("Steps data: \(stepsResult)")
}
