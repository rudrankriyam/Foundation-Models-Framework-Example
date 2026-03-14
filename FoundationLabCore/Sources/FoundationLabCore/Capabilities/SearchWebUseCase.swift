import Foundation

public struct SearchWebUseCase: CapabilityUseCase {
    public static let descriptor = CapabilityDescriptor(
        id: "foundation-models.search-web",
        displayName: "Search Web",
        summary: "Searches the web using a shared Foundation Models capability."
    )

    private let searcher: any WebSearching

    public init(searcher: any WebSearching = FoundationModelsWebSearcher()) {
        self.searcher = searcher
    }

    public func execute(_ request: SearchWebRequest) async throws -> TextGenerationResult {
        let query = request.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing query")
        }

        return try await searcher.searchWeb(for: request)
    }
}
