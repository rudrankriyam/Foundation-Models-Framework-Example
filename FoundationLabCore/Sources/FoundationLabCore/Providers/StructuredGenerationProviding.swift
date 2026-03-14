import Foundation
import FoundationModels

public protocol StructuredGenerationProviding: Sendable {
    func generate<Output: Generable & Sendable>(
        _ type: Output.Type,
        for request: StructuredGenerationRequest<Output>
    ) async throws -> StructuredGenerationResult<Output>
}
