//
//  ModelCompareResponseMetrics.swift
//  Adapter Studio
//
//  Created by Rudrank Riyam on 10/22/25.
//

import Foundation

/// Timing metrics captured over the lifecycle of a model response.
struct ModelCompareResponseMetrics: Sendable {

    /// Timestamp recorded when the request starts.
    let startedAt: Date

    private(set) var firstTokenAt: Date?
    private(set) var completedAt: Date?

    /// Records the first-token timestamp if it has not been set already.
    mutating func markFirstToken() {
        guard firstTokenAt == nil else { return }
        firstTokenAt = Date()
    }

    /// Records the completion timestamp.
    mutating func markCompleted() {
        completedAt = Date()
    }

    /// Time elapsed from the start of the request until the first token arrives.
    var timeToFirstToken: TimeInterval? {
        guard let firstTokenAt else { return nil }
        return firstTokenAt.timeIntervalSince(startedAt)
    }

    /// Total duration of the request from start until completion.
    var totalDuration: TimeInterval? {
        guard let completedAt else { return nil }
        return completedAt.timeIntervalSince(startedAt)
    }
}
