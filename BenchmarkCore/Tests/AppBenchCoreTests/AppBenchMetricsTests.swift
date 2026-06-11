import AppBenchCore
import Foundation
import Testing

struct AppBenchMetricsTests {
    @Test
    func computesNearestRankStatistics() {
        let distribution = AppBenchDistribution(values: [1, 2, 3, 4, 100])

        #expect(distribution.count == 5)
        #expect(distribution.minimum == 1)
        #expect(distribution.median == 3)
        #expect(distribution.p90 == 100)
        #expect(distribution.maximum == 100)
    }

    @Test
    func throughputUsesOutputTokensAndDecodeTime() {
        let start = Date(timeIntervalSince1970: 100)
        let first = Date(timeIntervalSince1970: 101)
        let end = Date(timeIntervalSince1970: 105)
        let metrics = AppBenchTrialMetrics(
            startedAt: start,
            endedAt: end,
            firstTokenAt: first,
            promptTokenEstimate: 500,
            responseTokenEstimate: 101,
            responseCharacterCount: 600,
            streamUpdateDates: [first, end]
        )

        #expect(metrics.decodeDuration == 4)
        #expect(metrics.outputTokensPerSecond == 25)
    }
}
