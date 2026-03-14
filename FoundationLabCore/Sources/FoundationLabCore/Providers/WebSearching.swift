import Foundation

public protocol WebSearching: Sendable {
    func searchWeb(for request: SearchWebRequest) async throws -> TextGenerationResult
}
