//
//  HealthDataManager.swift
//  Physiqa
//
//  Created by Rudrank Riyam on 6/23/25.
//

import Foundation
import HealthKit
import SwiftData
import Observation

@Observable
class HealthDataManager {
    private let healthStore = HKHealthStore()
    private var modelContext: ModelContext?

    var isAuthorized = false
    var authorizationStatus: String = "Not Determined"

    // Current health data
    var todaySteps: Double = 0
    var todayActiveEnergy: Double = 0
    var todayDistance: Double = 0
    var currentHeartRate: Double = 0
    var lastNightSleep: Double = 0

    init() {
        checkHealthKitAvailability()
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    private func checkHealthKitAvailability() {
        if !HKHealthStore.isHealthDataAvailable() {
            authorizationStatus = "HealthKit Not Available"
        }
    }

    // MARK: - Authorization
    func requestAuthorization() async throws {
        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.workoutType()
        ]

        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
        isAuthorized = true
        authorizationStatus = "Authorized"
    }

    // MARK: - Fetch Today's Data
    func fetchTodayHealthData() async {
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

    // MARK: - Steps
    private func fetchSteps(from startDate: Date, to endDate: Date) async {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let samplePredicate = HKSamplePredicate.quantitySample(type: stepType, predicate: predicate)

        let descriptor = HKStatisticsQueryDescriptor(
            predicate: samplePredicate,
            options: .cumulativeSum
        )

        do {
            let result = try await descriptor.result(for: healthStore)
            if let sum = result?.sumQuantity() {
                todaySteps = sum.doubleValue(for: HKUnit.count())
                await saveMetric(type: .steps, value: todaySteps)
            }
        } catch {
            // Handle steps fetch error silently
        }
    }

    // MARK: - Active Energy
    private func fetchActiveEnergy(from startDate: Date, to endDate: Date) async {
        guard let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else { return }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let samplePredicate = HKSamplePredicate.quantitySample(type: energyType, predicate: predicate)

        let descriptor = HKStatisticsQueryDescriptor(
            predicate: samplePredicate,
            options: .cumulativeSum
        )

        do {
            let result = try await descriptor.result(for: healthStore)
            if let sum = result?.sumQuantity() {
                todayActiveEnergy = sum.doubleValue(for: .kilocalorie())
                await saveMetric(type: .activeEnergy, value: todayActiveEnergy)
            }
        } catch {
            // Handle active energy fetch error silently
        }
    }

    // MARK: - Distance
    private func fetchDistance(from startDate: Date, to endDate: Date) async {
        guard let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) else { return }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let samplePredicate = HKSamplePredicate.quantitySample(type: distanceType, predicate: predicate)

        let descriptor = HKStatisticsQueryDescriptor(
            predicate: samplePredicate,
            options: .cumulativeSum
        )

        do {
            let result = try await descriptor.result(for: healthStore)
            if let sum = result?.sumQuantity() {
                let meters = sum.doubleValue(for: .meter())
                todayDistance = meters / 1000 // Convert to kilometers
                await saveMetric(type: .distance, value: todayDistance)
            }
        } catch {
            // Handle distance fetch error silently
        }
    }

    // MARK: - Heart Rate
    private func fetchLatestHeartRate() async {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }

        let descriptor = HKSampleQueryDescriptor(
            predicates: [HKSamplePredicate.quantitySample(type: heartRateType)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)],
            limit: 1
        )

        do {
            let samples = try await descriptor.result(for: healthStore)
            if let sample = samples.first {
                currentHeartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                await saveMetric(type: .heartRate, value: currentHeartRate)
            }
        } catch {
            // Handle heart rate fetch error silently
        }
    }

    // MARK: - Sleep
    private func fetchLastNightSleep() async {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -1, to: endDate)!

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

            lastNightSleep = totalSleepTime / 3600 // Convert to hours
            if lastNightSleep > 0 {
                await saveMetric(type: .sleep, value: lastNightSleep)
            }
        } catch {
            // Handle sleep fetch error silently
        }
    }

    // MARK: - Weekly Data
    func fetchWeeklyData() async -> [MetricType: [DailyMetricData]] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!

        var weeklyData: [MetricType: [DailyMetricData]] = [:]

        for metricType in [MetricType.steps, .activeEnergy, .sleep] {
            weeklyData[metricType] = await fetchDailyData(for: metricType, from: startDate, to: endDate)
        }

        return weeklyData
    }

    private func fetchDailyData(for metricType: MetricType, from startDate: Date, to endDate: Date) async -> [DailyMetricData] {
        var dailyData: [DailyMetricData] = []
        let calendar = Calendar.current

        var currentDate = startDate
        while currentDate <= endDate {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

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
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return dailyData
    }

    private func fetchStepsValue(from startDate: Date, to endDate: Date) async -> Double {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return 0 }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let samplePredicate = HKSamplePredicate.quantitySample(type: stepType, predicate: predicate)

        let descriptor = HKStatisticsQueryDescriptor(
            predicate: samplePredicate,
            options: .cumulativeSum
        )

        do {
            let result = try await descriptor.result(for: healthStore)
            if let sum = result?.sumQuantity() {
                return sum.doubleValue(for: HKUnit.count())
            }
        } catch {
            // Handle steps value fetch error silently
        }

        return 0
    }

    private func fetchActiveEnergyValue(from startDate: Date, to endDate: Date) async -> Double {
        guard let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else { return 0 }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let samplePredicate = HKSamplePredicate.quantitySample(type: energyType, predicate: predicate)

        let descriptor = HKStatisticsQueryDescriptor(
            predicate: samplePredicate,
            options: .cumulativeSum
        )

        do {
            let result = try await descriptor.result(for: healthStore)
            if let sum = result?.sumQuantity() {
                return sum.doubleValue(for: .kilocalorie())
            }
        } catch {
            // Handle energy value fetch error silently
        }

        return 0
    }

    private func fetchSleepValue(for date: Date) async -> Double {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return 0 }

        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: date)
        let startDate = calendar.date(byAdding: .day, value: -1, to: endDate)!

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

            return totalSleepTime / 3600 // Convert to hours
        } catch {
            // Handle sleep value fetch error silently
        }

        return 0
    }

    // MARK: - Save to SwiftData
    @MainActor
    private func saveMetric(type: MetricType, value: Double) async {
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
            // Handle metric save error silently
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
    static let shared = HealthDataManager()
}
