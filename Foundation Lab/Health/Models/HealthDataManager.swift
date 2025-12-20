//
//  HealthDataManager.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/23/25.
//

import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class HealthDataManager {
    // MARK: - Services

    let healthKitService: HealthKitService
    private(set) var healthRepository: HealthRepository

    // MARK: - Observable State

    var isAuthorized: Bool = false
    var todaySteps: Double = 0
    var todayActiveEnergy: Double = 0
    var todayDistance: Double = 0
    var currentHeartRate: Double = 0
    var lastNightSleep: Double = 0

    // MARK: - Initialization

    init() {
        self.healthKitService = HealthKitService()
        self.healthRepository = HealthRepository()
    }

    // MARK: - Authorization

    func requestAuthorization() async throws {
        try await healthKitService.requestAuthorization()
        isAuthorized = await healthKitService.isAuthorized
    }

    // MARK: - Fetch Today's Data

    func fetchTodayHealthData() async {
        let metrics = await healthKitService.fetchAllTodayMetrics()

        todaySteps = metrics.steps
        todayActiveEnergy = metrics.activeEnergy
        todayDistance = metrics.distance
        currentHeartRate = metrics.heartRate
        lastNightSleep = metrics.sleep

        healthRepository.saveMetrics([
            .steps: metrics.steps,
            .activeEnergy: metrics.activeEnergy,
            .distance: metrics.distance,
            .heartRate: metrics.heartRate,
            .sleep: metrics.sleep
        ])
    }

    // MARK: - Fetch Weekly Data

    func fetchWeeklyData() async -> [MetricType: [DailyMetricData]] {
        await healthKitService.fetchWeeklyData()
    }

    // MARK: - SwiftData Context

    func configureModelContext(_ context: ModelContext) {
        healthRepository.setModelContext(context)
    }
}

// MARK: - Singleton Instance

extension HealthDataManager {
    static let shared = HealthDataManager()
}
