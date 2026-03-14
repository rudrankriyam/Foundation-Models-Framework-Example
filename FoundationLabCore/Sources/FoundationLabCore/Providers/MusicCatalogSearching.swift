import Foundation

public protocol MusicCatalogSearching: Sendable {
    func searchMusic(for request: SearchMusicCatalogRequest) async throws -> TextGenerationResult
}
