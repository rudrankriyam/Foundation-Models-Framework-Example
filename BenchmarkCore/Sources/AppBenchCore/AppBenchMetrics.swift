import Foundation

public struct AppBenchTrialMetrics: Codable, Sendable {
    public let startedAt: Date
    public let endedAt: Date
    public let duration: TimeInterval
    public let timeToFirstToken: TimeInterval?
    public let decodeDuration: TimeInterval?
    public let promptTokenEstimate: Int
    public let responseTokenEstimate: Int
    public let outputTokensPerSecond: Double?
    public let outputCharactersPerSecond: Double?
    public let streamUpdateCount: Int
    public let maximumStreamUpdateGap: TimeInterval?

    public init(
        startedAt: Date,
        endedAt: Date,
        firstTokenAt: Date?,
        promptTokenEstimate: Int,
        responseTokenEstimate: Int,
        responseCharacterCount: Int,
        streamUpdateDates: [Date]
    ) {
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.duration = endedAt.timeIntervalSince(startedAt)
        self.timeToFirstToken = firstTokenAt.map { $0.timeIntervalSince(startedAt) }

        if let timeToFirstToken, duration > timeToFirstToken {
            let decodeDuration = duration - timeToFirstToken
            self.decodeDuration = decodeDuration
            self.outputTokensPerSecond = Double(max(0, responseTokenEstimate - 1)) / decodeDuration
            self.outputCharactersPerSecond = Double(responseCharacterCount) / decodeDuration
        } else {
            self.decodeDuration = nil
            self.outputTokensPerSecond = nil
            self.outputCharactersPerSecond = nil
        }

        self.promptTokenEstimate = promptTokenEstimate
        self.responseTokenEstimate = responseTokenEstimate
        self.streamUpdateCount = streamUpdateDates.count
        self.maximumStreamUpdateGap = zip(streamUpdateDates, streamUpdateDates.dropFirst())
            .map { $1.timeIntervalSince($0) }
            .max()
    }
}

public struct AppBenchDistribution: Codable, Sendable {
    public let count: Int
    public let minimum: Double?
    public let median: Double?
    public let mean: Double?
    public let p90: Double?
    public let maximum: Double?
    public let standardDeviation: Double?

    public init(values: [Double]) {
        let sorted = values.sorted()
        count = sorted.count
        minimum = sorted.first
        median = Self.percentile(0.5, values: sorted)
        p90 = Self.percentile(0.9, values: sorted)
        maximum = sorted.last

        if sorted.isEmpty {
            mean = nil
            standardDeviation = nil
        } else {
            let mean = sorted.reduce(0, +) / Double(sorted.count)
            self.mean = mean
            let variance = sorted.reduce(0) { $0 + pow($1 - mean, 2) } / Double(sorted.count)
            self.standardDeviation = sqrt(variance)
        }
    }

    private static func percentile(_ percentile: Double, values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let rank = Int(ceil(percentile * Double(values.count))) - 1
        return values[max(0, min(rank, values.count - 1))]
    }
}
