import Foundation

public struct SearchMusicCatalogUseCase: CapabilityUseCase {
    public static let descriptor = CapabilityDescriptor(
        id: "foundation-models.search-music-catalog",
        displayName: "Search Music Catalog",
        summary: "Searches the Apple Music catalog using shared Foundation Models orchestration."
    )

    private let searcher: any MusicCatalogSearching

    public init(searcher: any MusicCatalogSearching = FoundationModelsMusicCatalogSearcher()) {
        self.searcher = searcher
    }

    public func execute(_ request: SearchMusicCatalogRequest) async throws -> TextGenerationResult {
        let query = request.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing query")
        }

        return try await searcher.searchMusic(for: request)
    }
}
