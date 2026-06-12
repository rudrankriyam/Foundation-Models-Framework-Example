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
            inputTokenCount: 500,
            outputTokenCount: 101,
            firstStreamUpdateTokenCount: 1,
            tokenCountSource: .systemTokenizer,
            responseCharacterCount: 600,
            streamUpdateDates: [first, end]
        )

        #expect(metrics.decodeDuration == 4)
        #expect(metrics.outputTokensPerSecond == 25)
        #expect(metrics.tokenCountSource == .systemTokenizer)
    }

    @Test
    func throughputExcludesTheEntireFirstStreamUpdate() {
        let start = Date(timeIntervalSince1970: 100)
        let first = Date(timeIntervalSince1970: 101)
        let end = Date(timeIntervalSince1970: 105)
        let metrics = AppBenchTrialMetrics(
            startedAt: start,
            endedAt: end,
            firstTokenAt: first,
            inputTokenCount: 500,
            outputTokenCount: 101,
            firstStreamUpdateTokenCount: 11,
            tokenCountSource: .systemTokenizer,
            responseCharacterCount: 600,
            streamUpdateDates: [first, end]
        )

        #expect(metrics.outputTokensPerSecond == 22.5)
    }

    @Test
    func recordsContextMemoryAndWorstThermalState() {
        let start = Date(timeIntervalSince1970: 100)
        let first = Date(timeIntervalSince1970: 101)
        let end = Date(timeIntervalSince1970: 102)
        let metrics = AppBenchTrialMetrics(
            startedAt: start,
            endedAt: end,
            firstTokenAt: first,
            inputTokenCount: 500,
            outputTokenCount: 20,
            firstStreamUpdateTokenCount: 2,
            tokenCountSource: .sessionUsage,
            responseCharacterCount: 80,
            streamUpdateDates: [first, end],
            reasoningTokenCount: 12,
            contextSize: 4_000,
            resourceSnapshots: [
                .init(residentMemoryBytes: 100, thermalState: "nominal"),
                .init(residentMemoryBytes: 180, thermalState: "serious"),
                .init(residentMemoryBytes: 150, thermalState: "fair"),
            ]
        )

        #expect(metrics.contextUtilization == 0.125)
        #expect(metrics.peakObservedResidentMemoryBytes == 180)
        #expect(metrics.worstObservedThermalState == "serious")
        #expect(metrics.reasoningTokenCount == 12)
    }
}
