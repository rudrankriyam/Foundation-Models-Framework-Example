import Foundation

public struct TextGenerationResult: CapabilityResult, Sendable, Hashable {
    public let content: String
    public let metadata: CapabilityExecutionMetadata

    public init(content: String, metadata: CapabilityExecutionMetadata = CapabilityExecutionMetadata()) {
        self.content = content
        self.metadata = metadata
    }
}
