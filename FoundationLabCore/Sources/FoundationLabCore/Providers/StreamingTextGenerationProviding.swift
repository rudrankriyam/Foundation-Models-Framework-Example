import Foundation

public protocol StreamingTextGenerationProviding: Sendable {
    func streamText(
        for request: StreamingTextGenerationRequest,
        onPartialResponse: @escaping @Sendable (String) async -> Void
    ) async throws -> TextGenerationResult
}
