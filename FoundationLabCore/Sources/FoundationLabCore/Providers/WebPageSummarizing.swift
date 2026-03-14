import Foundation

public protocol WebPageSummarizing: Sendable {
    func summarizePage(for request: GenerateWebPageSummaryRequest) async throws -> TextGenerationResult
}
