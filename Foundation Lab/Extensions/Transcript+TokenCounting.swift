//
//  Transcript+TokenCounting.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import Foundation
import FoundationModels
// import NaturalLanguage // Unused; removed

// MARK: - Token Counting Extensions

extension Transcript.Entry {
    var estimatedTokenCount: Int {
        switch self {
        case .instructions(let instructions):
            return instructions.segments.reduce(0) { $0 + $1.estimatedTokenCount }

        case .prompt(let prompt):
            return prompt.segments.reduce(0) { $0 + $1.estimatedTokenCount }

        case .response(let response):
            return response.segments.reduce(0) { $0 + $1.estimatedTokenCount }

        case .toolCalls(let toolCalls):
            // Tool calls are structured, add overhead
            return toolCalls.reduce(0) { total, call in
                total + estimateTokensAdvanced(call.toolName) +
                estimateTokensForStructuredContent(call.arguments) + 5 // Call overhead
            }

        case .toolOutput(let output):
            return output.segments.reduce(0) { $0 + $1.estimatedTokenCount } + 3 // Output overhead
        @unknown default:
            fatalError()
        }
    }
}

extension Transcript.Segment {
    var estimatedTokenCount: Int {
        switch self {
        case .text(let textSegment):
            return estimateTokensAdvanced(textSegment.content)

        case .structure(let structuredSegment):
            return estimateTokensForStructuredContent(structuredSegment.content)
        @unknown default:
            fatalError()
        }
    }
}

extension Transcript {
    var estimatedTokenCount: Int {
        return self.reduce(0) { $0 + $1.estimatedTokenCount }
    }
}

// MARK: - Token Estimation Utilities

/// Estimates token count using Apple's guidance: 4.5 characters per token
func estimateTokensAdvanced(_ text: String) -> Int {
    guard !text.isEmpty else { return 0 }

    let characterCount = text.count

    // Simple: 4.5 characters per token across all content types
    let tokensPerChar = 1.0 / 4.5

    return max(1, Int(ceil(Double(characterCount) * tokensPerChar)))
}

/// Estimates token count for structured JSON content
func estimateTokensForStructuredContent(_ content: GeneratedContent) -> Int {
    let jsonString = content.jsonString
    let characterCount = jsonString.count

    // Use same 4.5 chars per token for JSON
    let tokensPerChar = 1.0 / 4.5

    return max(1, Int(ceil(Double(characterCount) * tokensPerChar)))
}

// MARK: - Helper Functions

// Removed unused helper functions

// MARK: - Context Window Management Utilities

extension Transcript {
    /// Returns the estimated token count with a larger safety buffer
    var safeEstimatedTokenCount: Int {
        // Add bigger buffer to account for underestimation
        let baseTokens = estimatedTokenCount
        let buffer = Int(Double(baseTokens) * 0.25) // 25% buffer
        let systemOverhead = 100 // Fixed overhead for system tokens

        return baseTokens + buffer + systemOverhead
    }

    /// Checks if the transcript is approaching the token limit (earlier trigger)
    func isApproachingLimit(threshold: Double = 0.70, maxTokens: Int = 4096) -> Bool {
        let currentTokens = safeEstimatedTokenCount
        let limitThreshold = Int(Double(maxTokens) * threshold)
        return currentTokens > limitThreshold
    }

    /// Returns a subset of entries that fit within the token budget
    func entriesWithinTokenBudget(_ budget: Int) -> [Transcript.Entry] {
        var result: [Transcript.Entry] = []
        var tokenCount = 0

        // Always include instructions first if they exist
        if let instructions = self.first(where: {
            if case .instructions = $0 { return true }
            return false
        }) {
            result.append(instructions)
            tokenCount += instructions.estimatedTokenCount
        }

        // Add other entries from newest to oldest until budget is reached
        let nonInstructionEntries = self.filter { entry in
            if case .instructions = entry { return false }
            return true
        }

        for entry in nonInstructionEntries.reversed() {
            let entryTokens = entry.estimatedTokenCount
            if tokenCount + entryTokens > budget { break }

            result.insert(entry, at: result.count)
            tokenCount += entryTokens
        }

        return result
    }
}
