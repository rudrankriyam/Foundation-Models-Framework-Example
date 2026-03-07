import Foundation

public struct CapabilityExecutionMetadata: CapabilityResult, Sendable, Hashable, Codable {
    public let provider: String?
    public let modelIdentifier: String?

    public init(provider: String? = nil, modelIdentifier: String? = nil) {
        self.provider = provider
        self.modelIdentifier = modelIdentifier
    }
}
