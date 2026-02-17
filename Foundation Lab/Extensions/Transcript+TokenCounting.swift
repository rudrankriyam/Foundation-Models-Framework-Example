//
//  Transcript+TokenCounting.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import Foundation
import FoundationModels

// MARK: - Token Counting Extensions (Estimation Fallback)

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
            return toolCalls.reduce(0) { total, call in
                total + estimateTokensAdvanced(call.toolName) +
                estimateTokensForStructuredContent(call.arguments) + 5
            }

        case .toolOutput(let output):
            return output.segments.reduce(0) { $0 + $1.estimatedTokenCount } + 3
        @unknown default:
            return 0
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
            return 0
        }
    }
}

extension Transcript {
    var estimatedTokenCount: Int {
        return self.reduce(0) { $0 + $1.estimatedTokenCount }
    }
}

// MARK: - Token Estimation Utilities

/// Estimates token count using a heuristic of ~4.5 characters per token.
/// Used as a fallback when the real tokenizer API is unavailable (pre-iOS 26.4).
func estimateTokensAdvanced(_ text: String) -> Int {
    guard !text.isEmpty else { return 0 }

    let characterCount = text.count
    let tokensPerChar = 1.0 / 4.5

    return max(1, Int(ceil(Double(characterCount) * tokensPerChar)))
}

/// Estimates token count for structured JSON content.
func estimateTokensForStructuredContent(_ content: GeneratedContent) -> Int {
    let jsonString = content.jsonString
    let characterCount = jsonString.count

    let tokensPerChar = 1.0 / 4.5

    return max(1, Int(ceil(Double(characterCount) * tokensPerChar)))
}

// MARK: - Real Token Counting (iOS 26.4+)

#if compiler(>=6.3)
@available(iOS 26.4, macOS 26.4, visionOS 26.4, *)
extension Transcript {
    /// Returns the real token count for the entire transcript using the system tokenizer.
    func realTokenCount(
        using model: SystemLanguageModel = .default
    ) async throws -> Int {
        try await model.tokenUsage(for: Array(self)).tokenCount
    }
}

@available(iOS 26.4, macOS 26.4, visionOS 26.4, *)
extension Instructions {
    /// Returns the real token count for instructions and optional tools.
    func realTokenCount(
        tools: [any Tool] = [],
        using model: SystemLanguageModel = .default
    ) async throws -> Int {
        try await model.tokenUsage(for: self, tools: tools).tokenCount
    }
}

@available(iOS 26.4, macOS 26.4, visionOS 26.4, *)
extension Prompt {
    /// Returns the real token count for a prompt.
    func realTokenCount(
        using model: SystemLanguageModel = .default
    ) async throws -> Int {
        try await model.tokenUsage(for: self).tokenCount
    }
}
#endif

// MARK: - Unified Token Counting

extension Transcript {
    /// Returns the best available token count: real on iOS 26.4+, estimated otherwise.
    func tokenCount(using model: SystemLanguageModel = .default) async -> Int {
        #if compiler(>=6.3)
        if #available(iOS 26.4, macOS 26.4, visionOS 26.4, *) {
            if let real = try? await realTokenCount(using: model) {
                return real
            }
        }
        #endif
        return estimatedTokenCount
    }

    /// Returns the token count with a safety buffer for context window management.
    func safeTokenCount(using model: SystemLanguageModel = .default) async -> Int {
        #if compiler(>=6.3)
        if #available(iOS 26.4, macOS 26.4, visionOS 26.4, *) {
            if let realTokens = try? await realTokenCount(using: model) {
                // Real counts don't need as large a buffer.
                let buffer = Int(Double(realTokens) * 0.05)
                return realTokens + buffer
            }
        }
        #endif

        // Estimated counts need a larger buffer to account for inaccuracy
        let baseTokens = estimatedTokenCount
        let buffer = Int(Double(baseTokens) * 0.25)
        let systemOverhead = 100
        return baseTokens + buffer + systemOverhead
    }

    /// Checks if the transcript is approaching the context window limit.
    func isApproachingLimit(
        threshold: Double = 0.70,
        maxTokens: Int = 4096,
        using model: SystemLanguageModel = .default
    ) async -> Bool {
        let currentTokens = await safeTokenCount(using: model)
        let limitThreshold = Int(Double(maxTokens) * threshold)
        return currentTokens > limitThreshold
    }

    /// Returns a subset of entries that fit within the token budget.
    /// Uses real token counts on iOS 26.4+, estimated counts otherwise.
    func entriesWithinTokenBudget(
        _ budget: Int,
        using model: SystemLanguageModel = .default
    ) async -> [Transcript.Entry] {
        var result: [Transcript.Entry] = []
        var usedTokens = 0

        if let instructions = self.first(where: {
            if case .instructions = $0 { return true }
            return false
        }) {
            result.append(instructions)
            usedTokens += await tokenCountForEntry(instructions, using: model)
        }

        let nonInstructionEntries = self.filter { entry in
            if case .instructions = entry { return false }
            return true
        }

        for entry in nonInstructionEntries.reversed() {
            let entryTokens = await tokenCountForEntry(entry, using: model)
            if usedTokens + entryTokens > budget { break }

            result.insert(entry, at: result.count)
            usedTokens += entryTokens
        }

        return result
    }

    /// Returns the best available token count for a single entry.
    private func tokenCountForEntry(
        _ entry: Transcript.Entry,
        using model: SystemLanguageModel = .default
    ) async -> Int {
        #if compiler(>=6.3)
        if #available(iOS 26.4, macOS 26.4, visionOS 26.4, *) {
            if let real = try? await model.tokenUsage(for: [entry]).tokenCount {
                return real
            }
        }
        #endif
        return entry.estimatedTokenCount
    }
}

// MARK: - Legacy Synchronous API (Estimation Only)

extension Transcript {
    /// Returns the estimated token count with a safety buffer.
    /// Prefer the async `safeTokenCount(using:)` when possible.
    var safeEstimatedTokenCount: Int {
        let baseTokens = estimatedTokenCount
        let buffer = Int(Double(baseTokens) * 0.25)
        let systemOverhead = 100
        return baseTokens + buffer + systemOverhead
    }
}
