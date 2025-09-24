//
//  02_SearchTool.swift
//  Exploring Foundation Models
//
//  Created by Rudrank Riyam on 9/24/25.
//

import Foundation
import FoundationModels
import Playgrounds

struct SearchTool: Tool {
    let name = "searchWeb"
    let description = "Search the web for information on any topic using Tavily API"

    @Generable
    struct Arguments {
        @Guide(description: "The search query to look up")
        var query: String
    }

    struct SearchResult: Encodable {
        let title: String
        let content: String
        let url: String
        let score: Double
    }

    func call(arguments: Arguments) async throws -> some PromptRepresentable {
        let searchQuery = arguments.query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !searchQuery.isEmpty else {
            return createErrorOutput(for: searchQuery, error: SearchError.emptyQuery)
        }

        // In a real implementation, you would:
        // 1. Make API call to Tavily
        // 2. Parse the response
        // 3. Return structured results

        // Simulated search results for demo
        let mockResults = [
            SearchResult(
                title: "Sample Search Result",
                content: "This is a mock search result for query: \(searchQuery)",
                url: "https://example.com/search",
                score: 0.95
            )
        ]

        return createSuccessOutput(from: mockResults)
    }

    private func createSuccessOutput(from results: [SearchResult]) -> GeneratedContent {
        let summary = results.map {
            "\($0.title)\n\($0.content)\nSource: \($0.url)"
        }.joined(separator: "\n\n")

        return GeneratedContent(properties: [
            "query": results.first?.title ?? "",
            "resultCount": results.count,
            "summary": summary,
            "status": "success"
        ])
    }

    private func createErrorOutput(for query: String, error: Error) -> GeneratedContent {
        GeneratedContent(properties: [
            "query": query,
            "error": "Unable to perform search: \(error.localizedDescription)",
            "resultCount": 0,
            "summary": "Search failed for query: '\(query)'",
            "status": "error"
        ])
    }
}

enum SearchError: Error, LocalizedError {
    case emptyQuery
    case invalidURL
    case apiError
    case missingAPIKey

    var errorDescription: String? {
        switch self {
        case .emptyQuery:
            return "Search query cannot be empty"
        case .invalidURL:
            return "Invalid search URL"
        case .apiError:
            return "Search API request failed"
        case .missingAPIKey:
            return "Tavily API key is required. Please configure it in Settings."
        }
    }
}