//
//  Transcript+TokenCounting.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import Foundation
import FoundationModels

// MARK: - Token Estimation (Fallback for pre-iOS 26.4)

extension Transcript.Entry {
    /// Estimates token count using a heuristic of ~4.5 characters per token.
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
        self.reduce(0) { $0 + $1.estimatedTokenCount }
    }
}

/// Estimates token count at ~4.5 characters per token.
func estimateTokensAdvanced(_ text: String) -> Int {
    guard !text.isEmpty else { return 0 }
    return max(1, Int(ceil(Double(text.count) / 4.5)))
}

/// Estimates token count for structured JSON content.
func estimateTokensForStructuredContent(_ content: GeneratedContent) -> Int {
    let count = content.jsonString.count
    return max(1, Int(ceil(Double(count) / 4.5)))
}

// MARK: - Real Token Counting (iOS 26.4+)

#if compiler(>=6.3)
@available(iOS 26.4, macOS 26.4, visionOS 26.4, *)
extension Transcript {
    /// Returns the real token count for the entire transcript using the system tokenizer.
    func realTokenCount(using model: SystemLanguageModel = .default) async throws -> Int {
        try await model.tokenUsage(for: Array(self)).tokenCount
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
    /// Uses a small buffer (5%) for real counts, larger buffer (25% + overhead) for estimates.
    func safeTokenCount(using model: SystemLanguageModel = .default) async -> Int {
        #if compiler(>=6.3)
        if #available(iOS 26.4, macOS 26.4, visionOS 26.4, *) {
            if let realTokens = try? await realTokenCount(using: model) {
                let buffer = Int(Double(realTokens) * 0.05)
                return realTokens + buffer
            }
        }
        #endif

        let baseTokens = estimatedTokenCount
        let buffer = Int(Double(baseTokens) * 0.25)
        return baseTokens + buffer + 100
    }

    /// Checks if the transcript is approaching the context window limit.
    func isApproachingLimit(
        threshold: Double = 0.70,
        maxTokens: Int = 4096,
        using model: SystemLanguageModel = .default
    ) async -> Bool {
        let currentTokens = await safeTokenCount(using: model)
        return currentTokens > Int(Double(maxTokens) * threshold)
    }

    /// Returns the most recent entries that fit within the token budget.
    /// On iOS 26.4+ uses binary search with batched real token counts for efficiency.
    /// Falls back to sequential estimation on older versions.
    func entriesWithinTokenBudget(
        _ budget: Int,
        using model: SystemLanguageModel = .default
    ) async -> [Transcript.Entry] {
        let instructionsEntry = self.first(where: {
            if case .instructions = $0 { return true }
            return false
        })

        let conversationEntries = self.filter { entry in
            if case .instructions = entry { return false }
            return true
        }

        #if compiler(>=6.3)
        if #available(iOS 26.4, macOS 26.4, visionOS 26.4, *) {
            return await realTokenBudgetWindow(
                instructions: instructionsEntry,
                conversation: conversationEntries,
                budget: budget,
                model: model
            ) ?? estimatedTokenBudgetWindow(
                instructions: instructionsEntry,
                conversation: conversationEntries,
                budget: budget
            )
        }
        #endif

        return estimatedTokenBudgetWindow(
            instructions: instructionsEntry,
            conversation: conversationEntries,
            budget: budget
        )
    }
}

// MARK: - Token Budget Window Implementations

private extension Transcript {
    /// Estimation-based windowing: sequential scan from most recent entries.
    func estimatedTokenBudgetWindow(
        instructions: Transcript.Entry?,
        conversation: [Transcript.Entry],
        budget: Int
    ) -> [Transcript.Entry] {
        var result: [Transcript.Entry] = []
        var usedTokens = 0

        if let instructions {
            result.append(instructions)
            usedTokens += instructions.estimatedTokenCount
        }

        for entry in conversation.reversed() {
            let entryTokens = entry.estimatedTokenCount
            if usedTokens + entryTokens > budget { break }
            result.append(entry)
            usedTokens += entryTokens
        }

        return result
    }

    #if compiler(>=6.3)
    /// Real token counting with binary search: O(log N) API calls instead of O(N).
    /// Returns nil if the token usage API fails, signaling fallback to estimation.
    @available(iOS 26.4, macOS 26.4, visionOS 26.4, *)
    func realTokenBudgetWindow(
        instructions: Transcript.Entry?,
        conversation: [Transcript.Entry],
        budget: Int,
        model: SystemLanguageModel
    ) async -> [Transcript.Entry]? {
        let base: [Transcript.Entry] = instructions.map { [$0] } ?? []

        guard let baseTokens = base.isEmpty
            ? 0
            : try? await model.tokenUsage(for: base).tokenCount
        else {
            return nil
        }

        if baseTokens > budget {
            return base
        }

        var low = 0
        var high = conversation.count

        while low < high {
            let mid = (low + high + 1) / 2
            let recentEntries = Array(conversation.suffix(mid))
            let candidate = base + recentEntries

            guard let tokens = try? await model.tokenUsage(for: candidate).tokenCount else {
                return nil
            }

            if tokens <= budget {
                low = mid
            } else {
                high = mid - 1
            }
        }

        return base + Array(conversation.suffix(low))
    }
    #endif
}
