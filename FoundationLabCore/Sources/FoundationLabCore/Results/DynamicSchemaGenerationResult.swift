import Foundation
import FoundationModels

public struct DynamicSchemaGenerationResult: CapabilityResult, Sendable {
    public let output: GeneratedContent
    public let metadata: CapabilityExecutionMetadata

    public init(
        output: GeneratedContent,
        metadata: CapabilityExecutionMetadata = CapabilityExecutionMetadata()
    ) {
        self.output = output
        self.metadata = metadata
    }
}
