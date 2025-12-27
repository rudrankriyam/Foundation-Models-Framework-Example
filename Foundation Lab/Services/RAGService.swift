//
//  RAGService.swift
//  FoundationLab
//
//  Service for RAG document indexing and search operations.
//

import Foundation
import LumoKit
import VecturaKit

/// Service handling RAG indexing operations.
final class RAGService {
    private let lumoKit: LumoKit
    private let chunkingConfig: ChunkingConfig

    init(lumoKit: LumoKit, chunkingConfig: ChunkingConfig) {
        self.lumoKit = lumoKit
        self.chunkingConfig = chunkingConfig
    }

    func indexDocument(url: URL) async throws -> [UUID] {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        return try await lumoKit.parseAndIndex(url: url, chunkingConfig: chunkingConfig)
    }

    func indexText(_ text: String) async throws -> [UUID] {
        let chunks = try lumoKit.chunkText(text, config: chunkingConfig)
        return try await lumoKit.addDocuments(texts: chunks.map { $0.text })
    }

    func indexSamples(_ texts: [(title: String, text: String)]) async throws -> Int {
        var count = 0
        for (_, text) in texts {
            let chunks = try lumoKit.chunkText(text, config: chunkingConfig)
            _ = try await lumoKit.addDocuments(texts: chunks.map { $0.text })
            count += 1
        }
        return count
    }

    func search(query: String) async throws -> [VecturaSearchResult] {
        try await lumoKit.semanticSearch(query: query, numResults: 5, threshold: 0.5)
    }

    func resetDatabase() async throws {
        try await lumoKit.resetDB()
    }

    var documentCount: Int {
        get async throws {
            try await lumoKit.documentCount()
        }
    }
}

// MARK: - Configuration

struct RAGConfig {
    let searchOptions: VecturaConfig.SearchOptions
    let chunkingConfig: ChunkingConfig

    static var `default`: RAGConfig {
        let options = VecturaConfig.SearchOptions(defaultNumResults: 5, minThreshold: 0.5)
        let chunking: ChunkingConfig
        do {
            chunking = try ChunkingConfig(chunkSize: 500, overlapPercentage: 0.15,
                                           strategy: .semantic, contentType: .prose)
        } catch {
            fatalError("Invalid chunking configuration: \(error)")
        }
        return RAGConfig(searchOptions: options, chunkingConfig: chunking)
    }
}
