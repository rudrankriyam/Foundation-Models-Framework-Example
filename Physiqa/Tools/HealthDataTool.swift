//
//  HealthDataTool.swift
//  Physiqa
//
//  Created by Rudrank Riyam on 6/23/25.
//

import Foundation
import FoundationModels
import SwiftData
import SwiftUI

struct HealthDataTool: Tool {
    let name = "fetchHealthData"
    let description = "Fetch current health data including steps, heart rate, sleep, and other metrics"
    
    @Generable
    struct Arguments {
        @Guide(description: "The type of health data to fetch: 'today', 'weekly', or specific metric like 'steps', 'heartRate', 'sleep', 'activeEnergy', 'distance'")
        var dataType: String
        
        @Guide(description: "Whether to fetch from HealthKit (true) or SwiftData cache (false). Defaults to false.")
        var refreshFromHealthKit: Bool?
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        let healthManager = HealthDataManager.shared
        
        switch arguments.dataType.lowercased() {
        case "today":
            return await fetchTodayData(healthManager: healthManager, refresh: arguments.refreshFromHealthKit ?? false)
        case "weekly":
            return await fetchWeeklyData(healthManager: healthManager)
        case "steps":
            return await fetchSpecificMetric(healthManager: healthManager, type: .steps, refresh: arguments.refreshFromHealthKit ?? false)
        case "heartrate":
            return await fetchSpecificMetric(healthManager: healthManager, type: .heartRate, refresh: arguments.refreshFromHealthKit ?? false)
        case "sleep":
            return await fetchSpecificMetric(healthManager: healthManager, type: .sleep, refresh: arguments.refreshFromHealthKit ?? false)
        case "activeenergy":
            return await fetchSpecificMetric(healthManager: healthManager, type: .activeEnergy, refresh: arguments.refreshFromHealthKit ?? false)
        case "distance":
            return await fetchSpecificMetric(healthManager: healthManager, type: .distance, refresh: arguments.refreshFromHealthKit ?? false)
        default:
            return createErrorOutput(error: "Invalid data type. Use 'today', 'weekly', 'steps', 'heartRate', 'sleep', 'activeEnergy', or 'distance'.")
        }
    }
    
    private func fetchTodayData(healthManager: HealthDataManager, refresh: Bool) async -> ToolOutput {
        if refresh {
            await healthManager.fetchTodayHealthData()
        }
        
        let metricsJSON = """
        {
            "steps": \(Int(healthManager.todaySteps)),
            "activeEnergy": \(Int(healthManager.todayActiveEnergy)),
            "distance": \(String(format: "%.2f", healthManager.todayDistance)),
            "heartRate": \(Int(healthManager.currentHeartRate)),
            "sleep": \(String(format: "%.1f", healthManager.lastNightSleep))
        }
        """
        
        return ToolOutput(
            GeneratedContent(properties: [
                "status": "success",
                "dataType": "today",
                "metrics": metricsJSON,
                "timestamp": ISO8601DateFormatter().string(from: Date()),
                "message": "Today's health data retrieved successfully"
            ])
        )
    }
    
    private func fetchWeeklyData(healthManager: HealthDataManager) async -> ToolOutput {
        let weeklyData = await healthManager.fetchWeeklyData()
        
        var weeklyStatsArray: [String] = []
        
        for (metric, dailyData) in weeklyData {
            let values = dailyData.map { $0.value }
            let total = values.reduce(0, +)
            let average = values.isEmpty ? 0 : total / Double(values.count)
            
            weeklyStatsArray.append("""
                "\(metric.rawValue)": {
                    "total": \(String(format: "%.0f", total)),
                    "average": \(String(format: "%.1f", average)),
                    "days": \(values.count)
                }
                """)
        }
        
        let weeklyStatsJSON = "{\(weeklyStatsArray.joined(separator: ","))}"
        
        return ToolOutput(
            GeneratedContent(properties: [
                "status": "success",
                "dataType": "weekly",
                "weeklyStats": weeklyStatsJSON,
                "timestamp": ISO8601DateFormatter().string(from: Date()),
                "message": "Weekly health data retrieved successfully"
            ])
        )
    }
    
    private func fetchSpecificMetric(healthManager: HealthDataManager, type: MetricType, refresh: Bool) async -> ToolOutput {
        if refresh {
            await healthManager.fetchTodayHealthData()
        }
        
        let value: Double
        switch type {
        case .steps:
            value = healthManager.todaySteps
        case .heartRate:
            value = healthManager.currentHeartRate
        case .sleep:
            value = healthManager.lastNightSleep
        case .activeEnergy:
            value = healthManager.todayActiveEnergy
        case .distance:
            value = healthManager.todayDistance
        default:
            return createErrorOutput(error: "Metric type not supported")
        }
        
        return ToolOutput(
            GeneratedContent(properties: [
                "status": "success",
                "metric": type.rawValue,
                "value": value,
                "unit": type.defaultUnit,
                "icon": type.icon,
                "timestamp": ISO8601DateFormatter().string(from: Date()),
                "message": "\(type.rawValue): \(formatValue(value, for: type))"
            ])
        )
    }
    
    private func formatValue(_ value: Double, for type: MetricType) -> String {
        switch type {
        case .steps, .activeEnergy:
            return "\(Int(value))"
        case .heartRate:
            return "\(Int(value)) bpm"
        case .sleep:
            return String(format: "%.1f hours", value)
        case .distance:
            return String(format: "%.2f km", value)
        default:
            return String(format: "%.1f", value)
        }
    }
    
    private func createErrorOutput(error: String) -> ToolOutput {
        return ToolOutput(
            GeneratedContent(properties: [
                "status": "error",
                "error": error,
                "message": "Failed to fetch health data"
            ])
        )
    }
}