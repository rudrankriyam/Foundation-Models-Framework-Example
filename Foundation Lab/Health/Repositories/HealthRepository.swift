//
//  HealthRepository.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 12/20/25.
//

import Foundation
import SwiftData
import OSLog

/// Repository for persisting health metrics to SwiftData.
/// Must be used on MainActor since ModelContext is not Sendable.
@MainActor
final class HealthRepository {
    private var modelContext: ModelContext?
    private let logger = VoiceLogging.health

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func saveMetric(type: MetricType, value: Double) {
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

    func saveMetrics(_ metrics: [MetricType: Double]) {
        guard let modelContext = modelContext else { return }

        for (type, value) in metrics {
            let metric = HealthMetric(
                type: type,
                value: value,
                unit: type.defaultUnit,
                timestamp: Date()
            )
            modelContext.insert(metric)
        }

        do {
            try modelContext.save()
        } catch {
            logger.error("Failed to save health metrics: \(error.localizedDescription)")
        }
    }

    func fetchRecentMetrics(days: Int = 7) -> [HealthMetric] {
        guard let modelContext = modelContext else { return [] }

        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) else {
            return []
        }

        let descriptor = FetchDescriptor<HealthMetric>(
            predicate: #Predicate { $0.timestamp >= startDate },
            sortBy: [SortDescriptor(\.timestamp)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            logger.error("Failed to fetch health metrics: \(error.localizedDescription)")
            return []
        }
    }
}
