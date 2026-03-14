import Foundation

public struct GenerateWebPageSummaryUseCase: CapabilityUseCase {
    public static let descriptor = CapabilityDescriptor(
        id: "foundation-models.generate-web-page-summary",
        displayName: "Generate Web Page Summary",
        summary: "Summarizes a web page using shared Foundation Models orchestration."
    )

    private let summarizer: any WebPageSummarizing

    public init(summarizer: any WebPageSummarizing = FoundationModelsWebPageSummarizer()) {
        self.summarizer = summarizer
    }

    public func execute(_ request: GenerateWebPageSummaryRequest) async throws -> TextGenerationResult {
        let trimmedURL = request.url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURL.isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing URL")
        }

        guard let parsedURL = URL(string: trimmedURL),
              let scheme = parsedURL.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              parsedURL.host != nil else {
            throw FoundationLabCoreError.invalidRequest("URL must use http or https")
        }

        return try await summarizer.summarizePage(for: request)
    }
}
