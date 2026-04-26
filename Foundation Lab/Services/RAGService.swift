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
@MainActor
final class RAGService {
    private let lumoKit: LumoKit
    private let chunkingConfig: ChunkingConfig

    init(lumoKit: LumoKit, chunkingConfig: ChunkingConfig) {
        self.lumoKit = lumoKit
        self.chunkingConfig = chunkingConfig
    }

    func indexDocument(url: URL) async throws -> [UUID] {
        let readableURL = try copyImportedDocumentToAppStorage(from: url)
        return try await lumoKit.parseAndIndex(url: readableURL, chunkingConfig: chunkingConfig)
    }

    private func copyImportedDocumentToAppStorage(from url: URL) throws -> URL {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let importsDirectory = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        .appendingPathComponent("RAGImports", isDirectory: true)

        try FileManager.default.createDirectory(
            at: importsDirectory,
            withIntermediateDirectories: true
        )

        let fileName = url.lastPathComponent.isEmpty ? "ImportedDocument" : url.lastPathComponent
        let destinationURL = importsDirectory.appendingPathComponent("\(UUID().uuidString)-\(fileName)")
        try FileManager.default.copyItem(at: url, to: destinationURL)
        return destinationURL
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

    static func makeDefault() throws -> RAGConfig {
        let options = VecturaConfig.SearchOptions(defaultNumResults: 5, minThreshold: 0.5)
        let chunking = try ChunkingConfig(
            chunkSize: 500,
            overlapPercentage: 0.15,
            strategy: .semantic,
            contentType: .prose
        )
        return RAGConfig(searchOptions: options, chunkingConfig: chunking)
    }
}
