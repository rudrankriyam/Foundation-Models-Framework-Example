import Foundation

public struct RunSchemaExampleResult: CapabilityResult, Sendable, Hashable, Codable {
    public let content: String
    public let metadata: CapabilityExecutionMetadata

    public init(
        content: String,
        metadata: CapabilityExecutionMetadata = CapabilityExecutionMetadata()
    ) {
        self.content = content
        self.metadata = metadata
    }
}
