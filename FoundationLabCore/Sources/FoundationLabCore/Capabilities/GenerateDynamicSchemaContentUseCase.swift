import Foundation

public struct GenerateDynamicSchemaContentUseCase: CapabilityUseCase {
    public static let descriptor = CapabilityDescriptor(
        id: "foundation-models.generate-dynamic-schema",
        displayName: "Generate Dynamic Schema Content",
        summary: "Generates content using a runtime-defined generation schema."
    )

    private let provider: any DynamicSchemaGenerationProviding

    public init(provider: any DynamicSchemaGenerationProviding = FoundationModelsDynamicSchemaGenerator()) {
        self.provider = provider
    }

    public func execute(
        _ request: DynamicSchemaGenerationRequest
    ) async throws -> DynamicSchemaGenerationResult {
        guard !request.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing prompt")
        }

        return try await provider.generate(for: request)
    }
}
