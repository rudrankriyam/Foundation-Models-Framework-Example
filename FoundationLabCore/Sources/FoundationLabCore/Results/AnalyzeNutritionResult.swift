import Foundation

public struct AnalyzeNutritionResult: CapabilityResult, Sendable, Hashable, Codable {
    public let analysis: NutritionAnalysis
    public let metadata: CapabilityExecutionMetadata

    public init(
        analysis: NutritionAnalysis,
        metadata: CapabilityExecutionMetadata = CapabilityExecutionMetadata()
    ) {
        self.analysis = analysis
        self.metadata = metadata
    }
}
