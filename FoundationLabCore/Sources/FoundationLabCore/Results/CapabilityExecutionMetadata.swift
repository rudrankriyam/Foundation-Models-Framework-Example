import Foundation

public struct CapabilityExecutionMetadata: CapabilityResult, Sendable, Hashable, Codable {
    public let provider: String?
    public let modelIdentifier: String?
    public let tokenCount: Int?

    public init(
        provider: String? = nil,
        modelIdentifier: String? = nil,
        tokenCount: Int? = nil
    ) {
        self.provider = provider
        self.modelIdentifier = modelIdentifier
        self.tokenCount = tokenCount
    }
}
