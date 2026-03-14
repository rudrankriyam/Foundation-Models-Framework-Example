import Foundation
import FoundationModels

public struct GenerateStructuredDataUseCase<Output: Generable & Sendable>: CapabilityUseCase {
    public static var descriptor: CapabilityDescriptor {
        CapabilityDescriptor(
            id: "foundation-models.generate-structured-data",
            displayName: "Generate Structured Data",
            summary: "Generates type-safe structured data using Foundation Models."
        )
    }

    private let provider: any StructuredGenerationProviding

    public init(provider: any StructuredGenerationProviding = FoundationModelsStructuredGenerator()) {
        self.provider = provider
    }

    public func execute(
        _ request: StructuredGenerationRequest<Output>
    ) async throws -> StructuredGenerationResult<Output> {
        guard !request.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing prompt")
        }

        return try await provider.generate(Output.self, for: request)
    }
}
