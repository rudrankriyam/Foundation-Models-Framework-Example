import Foundation

public protocol StreamingTextGenerationProviding: Sendable {
    func streamText(
        for request: StreamingTextGenerationRequest,
        onPartialResponse: @escaping @Sendable (String) -> Void
    ) async throws -> TextGenerationResult
}
