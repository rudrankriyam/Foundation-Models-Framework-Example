import Foundation

public protocol StructuredGenerationProviding: Sendable {
    func generate<Output: Decodable & Sendable>(
        _ type: Output.Type,
        for request: StructuredGenerationRequest<Output>
    ) async throws -> StructuredGenerationResult<Output>
}
