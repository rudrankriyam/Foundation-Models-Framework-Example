import Foundation

public protocol TextGenerationProviding: Sendable {
    func generateText(for request: TextGenerationRequest) async throws -> TextGenerationResult
}
