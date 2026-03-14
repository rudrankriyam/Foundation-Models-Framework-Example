import Foundation

public struct GenerateTextUseCase: CapabilityUseCase {
    public static let descriptor = CapabilityDescriptor(
        id: "foundation-models.generate-text",
        displayName: "Generate Text",
        summary: "Generates text from a prompt using Foundation Models."
    )

    private let provider: any TextGenerationProviding

    public init(provider: any TextGenerationProviding = FoundationModelsTextGenerator()) {
        self.provider = provider
    }

    public func execute(_ request: TextGenerationRequest) async throws -> TextGenerationResult {
        guard !request.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing prompt")
        }

        return try await provider.generateText(for: request)
    }
}
