//
//  HealthDataManager.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/23/25.
//

import Foundation
import HealthKit
import SwiftData
import Observation
import OSLog

@Observable
class HealthDataManager {
    private var healthStore: HKHealthStore?
    private var modelContext: ModelContext?
    private let logger = VoiceLogging.health

    // Constants
    private let metersToKilometers: Double = 1000.0
    private let secondsToHours: Double = 3600.0
    private let healthKitUnavailableErrorCode = -1

    var isAuthorized = false

    init() {
        #if os(iOS)
        if HKHealthStore.isHealthDataAvailable() {
            self.healthStore = HKHealthStore()
        }
        #endif
    }

    // Current health data
    var todaySteps: Double = 0
    var todayActiveEnergy: Double = 0
    var todayDistance: Double = 0
    var currentHeartRate: Double = 0
    var lastNightSleep: Double = 0

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Authorization
    func requestAuthorization() async throws {
        guard let healthStore = healthStore else {
            throw NSError(
                domain: "HealthDataManager",
                code: healthKitUnavailableErrorCode,
                userInfo: [NSLocalizedDescriptionKey: String(localized: "HealthKit is not available")]
            )
        }

        guard let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount),
              let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
              let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
              let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate),
              let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw NSError(
                domain: "HealthDataManager",
                code: healthKitUnavailableErrorCode,
                userInfo: [
                    NSLocalizedDescriptionKey: String(
                        localized: "Required HealthKit types are not available"
                    )
                ]
            )
        }

        let readTypes: Set<HKObjectType> = [
            stepCountType,
            activeEnergyType,
            distanceType,
            heartRateType,
            sleepType,
            HKObjectType.workoutType()
        ]

        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
        isAuthorized = true
    }

    // MARK: - Fetch Today's Data
    func fetchTodayHealthData() async {
        guard healthStore != nil else { return }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = Date()

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.fetchSteps(from: startOfDay, to: endOfDay)
            }
            group.addTask {
                await self.fetchActiveEnergy(from: startOfDay, to: endOfDay)
            }
            group.addTask {
                await self.fetchDistance(from: startOfDay, to: endOfDay)
            }
            group.addTask {
                await self.fetchLatestHeartRate()
            }
            group.addTask {
                await self.fetchLastNightSleep()
            }
        }
    }

}

extension HealthDataManager {
    // MARK: - Weekly Data
    func fetchWeeklyData() async -> [MetricType: [DailyMetricData]] {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) else {
            logger.error("Failed to calculate start date for weekly data")
            return [:]
        }

        var weeklyData: [MetricType: [DailyMetricData]] = [:]

        for metricType in [MetricType.steps, .activeEnergy, .sleep] {
            weeklyData[metricType] = await fetchDailyData(for: metricType, from: startDate, to: endDate)
        }

        return weeklyData
    }
}

private extension HealthDataManager {
    struct QuantityQueryConfig {
        let quantityTypeIdentifier: HKQuantityTypeIdentifier
        let unit: HKUnit
        let metricType: MetricType
    }

    func fetchQuantityData(
        config: QuantityQueryConfig,
        from startDate: Date,
        to endDate: Date,
        updateUI: @MainActor (Double) -> Void
    ) async {
        guard let healthStore = healthStore,
              let quantityType = HKObjectType.quantityType(forIdentifier: config.quantityTypeIdentifier) else {
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let samplePredicate = HKSamplePredicate.quantitySample(type: quantityType, predicate: predicate)

        let descriptor = HKStatisticsQueryDescriptor(
            predicate: samplePredicate,
            options: .cumulativeSum
        )

        do {
            let result = try await descriptor.result(for: healthStore)
            if let sum = result?.sumQuantity() {
                let value = sum.doubleValue(for: config.unit)
                await updateUI(value)
                await saveMetric(type: config.metricType, value: value)
            }
        } catch {
            logger.error("Failed to fetch \(config.quantityTypeIdentifier.rawValue) data: \(error.localizedDescription)")
        }
    }

    func fetchQuantityValue(
        quantityTypeIdentifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        from startDate: Date,
        to endDate: Date
    ) async -> Double {
        guard let healthStore = healthStore,
              let quantityType = HKObjectType.quantityType(forIdentifier: quantityTypeIdentifier) else {
            return 0
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let samplePredicate = HKSamplePredicate.quantitySample(type: quantityType, predicate: predicate)

        let descriptor = HKStatisticsQueryDescriptor(
            predicate: samplePredicate,
            options: .cumulativeSum
        )

        do {
            let result = try await descriptor.result(for: healthStore)
            if let sum = result?.sumQuantity() {
                return sum.doubleValue(for: unit)
            }
        } catch {
            logger.error("Failed to fetch \(quantityTypeIdentifier.rawValue) value: \(error.localizedDescription)")
        }

        return 0
    }

    func fetchSteps(from startDate: Date, to endDate: Date) async {
        await fetchQuantityData(
            config: QuantityQueryConfig(
                quantityTypeIdentifier: .stepCount,
                unit: HKUnit.count(),
                metricType: .steps
            ),
            from: startDate,
            to: endDate,
            updateUI: { self.todaySteps = $0 }
        )
    }

    func fetchActiveEnergy(from startDate: Date, to endDate: Date) async {
        await fetchQuantityData(
            config: QuantityQueryConfig(
                quantityTypeIdentifier: .activeEnergyBurned,
                unit: .kilocalorie(),
                metricType: .activeEnergy
            ),
            from: startDate,
            to: endDate,
            updateUI: { self.todayActiveEnergy = $0 }
        )
    }

    func fetchDistance(from startDate: Date, to endDate: Date) async {
        await fetchQuantityData(
            config: QuantityQueryConfig(
                quantityTypeIdentifier: .distanceWalkingRunning,
                unit: .meter(),
                metricType: .distance
            ),
            from: startDate,
            to: endDate,
            updateUI: { self.todayDistance = $0 / self.metersToKilometers } // Convert meters to kilometers
        )
    }

    func fetchLatestHeartRate() async {
        guard let healthStore = healthStore, let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }

        let descriptor = HKSampleQueryDescriptor(
            predicates: [HKSamplePredicate.quantitySample(type: heartRateType)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)],
            limit: 1
        )

        do {
            let samples = try await descriptor.result(for: healthStore)
            if let sample = samples.first {
                let value = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                await MainActor.run {
                    self.currentHeartRate = value
                }
                await saveMetric(type: .heartRate, value: value)
            }
        } catch {
            logger.error("Failed to fetch heart rate data: \(error.localizedDescription)")
        }
    }

    func fetchLastNightSleep() async {
        guard let healthStore = healthStore, let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -1, to: endDate) else {
            logger.error("Failed to calculate start date for sleep data")
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let samplePredicate = HKSamplePredicate.categorySample(type: sleepType, predicate: predicate)

        let descriptor = HKSampleQueryDescriptor(
            predicates: [samplePredicate],
            sortDescriptors: [SortDescriptor(\.startDate, order: .forward)]
        )

        do {
            let sleepSamples = try await descriptor.result(for: healthStore)
            var totalSleepTime: TimeInterval = 0

            for sample in sleepSamples {
                let duration = sample.endDate.timeIntervalSince(sample.startDate)
                totalSleepTime += duration
            }

            let value = totalSleepTime / secondsToHours
            await MainActor.run {
                self.lastNightSleep = value
            }
            if value > 0 {
                await saveMetric(type: .sleep, value: value)
            }
        } catch {
            logger.error("Failed to fetch sleep data: \(error.localizedDescription)")
        }
    }

    func fetchDailyData(
        for metricType: MetricType,
        from startDate: Date,
        to endDate: Date
    ) async -> [DailyMetricData] {
        var dailyData: [DailyMetricData] = []
        let calendar = Calendar.current

        var currentDate = startDate
        while currentDate <= endDate {
            let dayStart = calendar.startOfDay(for: currentDate)
            guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                logger.error("Failed to calculate day end date")
                break
            }

            let value: Double
            switch metricType {
            case .steps:
                value = await fetchStepsValue(from: dayStart, to: dayEnd)
            case .activeEnergy:
                value = await fetchActiveEnergyValue(from: dayStart, to: dayEnd)
            case .sleep:
                value = await fetchSleepValue(for: dayStart)
            default:
                value = 0
            }

            dailyData.append(DailyMetricData(date: currentDate, value: value))
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                logger.error("Failed to calculate next date")
                break
            }
            currentDate = nextDate
        }

        return dailyData
    }

    func fetchStepsValue(from startDate: Date, to endDate: Date) async -> Double {
        await fetchQuantityValue(
            quantityTypeIdentifier: .stepCount,
            unit: HKUnit.count(),
            from: startDate,
            to: endDate
        )
    }

    func fetchActiveEnergyValue(from startDate: Date, to endDate: Date) async -> Double {
        await fetchQuantityValue(
            quantityTypeIdentifier: .activeEnergyBurned,
            unit: .kilocalorie(),
            from: startDate,
            to: endDate
        )
    }

    func fetchSleepValue(for date: Date) async -> Double {
        guard let healthStore = healthStore, let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return 0 }

        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: date)
        guard let startDate = calendar.date(byAdding: .day, value: -1, to: endDate) else {
            logger.error("Failed to calculate start date for sleep value")
            return 0
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let samplePredicate = HKSamplePredicate.categorySample(type: sleepType, predicate: predicate)

        let descriptor = HKSampleQueryDescriptor(
            predicates: [samplePredicate],
            sortDescriptors: [SortDescriptor(\.startDate, order: .forward)]
        )

        do {
            let sleepSamples = try await descriptor.result(for: healthStore)
            var totalSleepTime: TimeInterval = 0

            for sample in sleepSamples {
                let duration = sample.endDate.timeIntervalSince(sample.startDate)
                totalSleepTime += duration
            }

            return totalSleepTime / secondsToHours
        } catch {
            logger.error("Failed to fetch sleep value: \(error.localizedDescription)")
        }

        return 0
    }
}

@MainActor
private extension HealthDataManager {
    func saveMetric(type: MetricType, value: Double) async {
        guard let modelContext = modelContext else { return }

        let metric = HealthMetric(
            type: type,
            value: value,
            unit: type.defaultUnit,
            timestamp: Date()
        )

        modelContext.insert(metric)

        do {
            try modelContext.save()
        } catch {
            logger.error("Failed to save health metric: \(error.localizedDescription)")
        }
    }
}

// MARK: - Supporting Types
struct DailyMetricData {
    let date: Date
    let value: Double
}

// MARK: - Singleton Instance
extension HealthDataManager {
    /// Shared singleton instance of HealthDataManager.
    /// This is thread-safe and uses lazy initialization.
    /// The singleton pattern is appropriate here as HealthKit data access
    /// should be centralized and shared across the app.
    static let shared = HealthDataManager()
}
