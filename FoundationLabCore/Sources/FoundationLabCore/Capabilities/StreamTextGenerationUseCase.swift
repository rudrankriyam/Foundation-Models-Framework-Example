import Foundation

public struct StreamTextGenerationUseCase: Sendable {
    public static let descriptor = CapabilityDescriptor(
        id: "foundation-models.stream-text",
        displayName: "Stream Text",
        summary: "Streams text generation updates using Foundation Models."
    )

    private let provider: any StreamingTextGenerationProviding

    public init(provider: any StreamingTextGenerationProviding = FoundationModelsStreamingTextGenerator()) {
        self.provider = provider
    }

    public func execute(
        _ request: StreamingTextGenerationRequest,
        onPartialResponse: @escaping @Sendable (String) async -> Void
    ) async throws -> TextGenerationResult {
        guard !request.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing prompt")
        }

        return try await provider.streamText(
            for: request,
            onPartialResponse: onPartialResponse
        )
    }
}
