import Foundation

public protocol DynamicSchemaGenerationProviding: Sendable {
    func generate(for request: DynamicSchemaGenerationRequest) async throws -> DynamicSchemaGenerationResult
}
