import Foundation

public protocol NutritionAnalyzing: Sendable {
    func analyzeNutrition(
        for request: AnalyzeNutritionRequest
    ) async throws -> AnalyzeNutritionResult
}
