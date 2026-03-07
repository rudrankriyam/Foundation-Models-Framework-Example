import Foundation

public struct StructuredGenerationResult<Output: Sendable>: CapabilityResult, Sendable {
    public let output: Output
    public let metadata: CapabilityExecutionMetadata

    public init(output: Output, metadata: CapabilityExecutionMetadata = CapabilityExecutionMetadata()) {
        self.output = output
        self.metadata = metadata
    }
}
