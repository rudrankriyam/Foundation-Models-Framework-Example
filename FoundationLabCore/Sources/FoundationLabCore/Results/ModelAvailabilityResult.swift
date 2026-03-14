import Foundation

public enum ModelAvailabilityUnavailableReason: String, Sendable, Hashable, Codable {
    case deviceNotEligible
    case appleIntelligenceNotEnabled
    case modelNotReady
    case unknown
}

public struct ModelAvailabilityResult: CapabilityResult, Sendable, Hashable, Codable {
    public let isAvailable: Bool
    public let reason: ModelAvailabilityUnavailableReason?
    public let metadata: CapabilityExecutionMetadata

    public init(
        isAvailable: Bool,
        reason: ModelAvailabilityUnavailableReason? = nil,
        metadata: CapabilityExecutionMetadata = CapabilityExecutionMetadata()
    ) {
        self.isAvailable = isAvailable
        self.reason = reason
        self.metadata = metadata
    }
}
