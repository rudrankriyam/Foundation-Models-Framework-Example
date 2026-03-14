import Foundation

public struct GenerateHealthEncouragementResult: CapabilityResult, Sendable, Hashable, Codable {
    public let message: String
    public let metadata: CapabilityExecutionMetadata

    public init(
        message: String,
        metadata: CapabilityExecutionMetadata = CapabilityExecutionMetadata()
    ) {
        self.message = message
        self.metadata = metadata
    }
}
