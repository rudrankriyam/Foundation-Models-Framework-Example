import Foundation

public struct FoundationLabGenerationOptions: Sendable, Hashable, Codable {
    public enum SamplingMode: Sendable, Hashable, Codable {
        case greedy
        case randomTop(Int, seed: UInt64? = nil)
        case randomProbabilityThreshold(Double, seed: UInt64? = nil)
    }

    public let sampling: SamplingMode?
    public let temperature: Double?
    public let maximumResponseTokens: Int?

    public init(
        sampling: SamplingMode? = nil,
        temperature: Double? = nil,
        maximumResponseTokens: Int? = nil
    ) {
        self.sampling = sampling
        self.temperature = temperature
        self.maximumResponseTokens = maximumResponseTokens
    }
}
