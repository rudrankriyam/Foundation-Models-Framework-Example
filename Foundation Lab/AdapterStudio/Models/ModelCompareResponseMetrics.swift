#if os(macOS)
import Foundation

struct ModelCompareResponseMetrics: Sendable {
    let startedAt: Date

    private(set) var firstTokenAt: Date?
    private(set) var completedAt: Date?

    mutating func markFirstToken(at date: Date = .now) {
        guard firstTokenAt == nil else { return }
        firstTokenAt = date
    }

    mutating func markCompleted(at date: Date = .now) {
        completedAt = date
    }

    var timeToFirstToken: TimeInterval? {
        guard let firstTokenAt else { return nil }
        return firstTokenAt.timeIntervalSince(startedAt)
    }

    var totalDuration: TimeInterval? {
        guard let completedAt else { return nil }
        return completedAt.timeIntervalSince(startedAt)
    }
}
#endif
