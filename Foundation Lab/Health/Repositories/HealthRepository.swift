//
//  HealthRepository.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 12/20/25.
//

import Foundation
import SwiftData
import OSLog

actor HealthRepository {
    private var modelContext: ModelContext?
    private let logger = VoiceLogging.health

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

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

    func fetchRecentMetrics(days: Int = 7) async -> [HealthMetric] {
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
