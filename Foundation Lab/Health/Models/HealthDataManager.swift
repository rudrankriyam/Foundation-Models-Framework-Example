//
//  HealthDataManager.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/23/25.
//

import Foundation
import SwiftData
import Observation

@Observable
final class HealthDataManager {
    // MARK: - Services

    let healthKitService = HealthKitService()
    let healthRepository = HealthRepository()

    // MARK: - Observable State

    var isAuthorized: Bool = false
    var todaySteps: Double = 0
    var todayActiveEnergy: Double = 0
    var todayDistance: Double = 0
    var currentHeartRate: Double = 0
    var lastNightSleep: Double = 0

    // MARK: - Initialization

    init() {}

    // MARK: - Authorization

    func requestAuthorization() async throws {
        try await healthKitService.requestAuthorization()
        isAuthorized = await healthKitService.isAuthorized
    }

    // MARK: - Fetch Today's Data

    func fetchTodayHealthData() async {
        await healthKitService.fetchTodayHealthData()

        // Update observable state
        todaySteps = await healthKitService.fetchSteps(from: startOfDay, to: Date())
        todayActiveEnergy = await healthKitService.fetchActiveEnergy(from: startOfDay, to: Date())
        todayDistance = await healthKitService.fetchDistance(from: startOfDay, to: Date())
        currentHeartRate = await healthKitService.fetchLatestHeartRate()
        lastNightSleep = await healthKitService.fetchLastNightSleep()

        // Save to SwiftData
        await saveCurrentMetrics()
    }

    // MARK: - Fetch Weekly Data

    func fetchWeeklyData() async -> [MetricType: [DailyMetricData]] {
        await healthKitService.fetchWeeklyData()
    }

    // MARK: - Private Helpers

    private var startOfDay: Date {
        Calendar.current.startOfDay(for: Date())
    }

    private func saveCurrentMetrics() async {
        await healthRepository.saveMetric(type: .steps, value: todaySteps)
        await healthRepository.saveMetric(type: .activeEnergy, value: todayActiveEnergy)
        await healthRepository.saveMetric(type: .heartRate, value: currentHeartRate)
        await healthRepository.saveMetric(type: .sleep, value: lastNightSleep)
    }
}

// MARK: - SwiftData Context

extension HealthDataManager {
    func setModelContext(_ context: ModelContext) {
        Task {
            await healthRepository.setModelContext(context)
        }
    }
}

// MARK: - Singleton Instance

extension HealthDataManager {
    static let shared = HealthDataManager()
}
