import Foundation
import FoundationModels

extension Transcript.Entry {
    public var foundationLabEstimatedTokenCount: Int {
        switch self {
        case .instructions(let instructions):
            return instructions.segments.reduce(0) { $0 + $1.foundationLabEstimatedTokenCount }
        case .prompt(let prompt):
            return prompt.segments.reduce(0) { $0 + $1.foundationLabEstimatedTokenCount }
        case .response(let response):
            return response.segments.reduce(0) { $0 + $1.foundationLabEstimatedTokenCount }
        case .toolCalls(let toolCalls):
            return toolCalls.reduce(0) { total, call in
                total + foundationLabEstimateTokens(call.toolName) +
                foundationLabEstimateStructuredTokens(call.arguments) + 5
            }
        case .toolOutput(let output):
            return output.segments.reduce(0) { $0 + $1.foundationLabEstimatedTokenCount } + 3
        @unknown default:
            return 0
        }
    }
}

extension Transcript.Segment {
    public var foundationLabEstimatedTokenCount: Int {
        switch self {
        case .text(let textSegment):
            return foundationLabEstimateTokens(textSegment.content)
        case .structure(let structuredSegment):
            return foundationLabEstimateStructuredTokens(structuredSegment.content)
        @unknown default:
            return 0
        }
    }
}

public extension Transcript {
    var foundationLabEstimatedTokenCount: Int {
        reduce(0) { $0 + $1.foundationLabEstimatedTokenCount }
    }

    func foundationLabTokenCount(
        using model: SystemLanguageModel = .default
    ) async -> Int {
        #if compiler(>=6.3)
        if #available(iOS 26.4, macOS 26.4, visionOS 26.4, *),
           let realTokenCount = try? await model.tokenCount(for: Array(self)) {
            return realTokenCount
        }
        #endif

        return foundationLabEstimatedTokenCount
    }

    func foundationLabSafeTokenCount(
        using model: SystemLanguageModel = .default
    ) async -> Int {
        #if compiler(>=6.3)
        if #available(iOS 26.4, macOS 26.4, visionOS 26.4, *),
           let realTokens = try? await model.tokenCount(for: Array(self)) {
            let buffer = Int(Double(realTokens) * 0.05)
            return realTokens + buffer
        }
        #endif

        let baseTokens = foundationLabEstimatedTokenCount
        let buffer = Int(Double(baseTokens) * 0.25)
        return baseTokens + buffer + 100
    }

    func foundationLabIsApproachingLimit(
        threshold: Double = 0.70,
        maxTokens: Int = 4096,
        using model: SystemLanguageModel = .default
    ) async -> Bool {
        let currentTokens = await foundationLabSafeTokenCount(using: model)
        return currentTokens > Int(Double(maxTokens) * threshold)
    }

    func foundationLabEntriesWithinTokenBudget(
        _ budget: Int,
        using model: SystemLanguageModel = .default
    ) async -> [Transcript.Entry] {
        let instructionsEntry = first(where: {
            if case .instructions = $0 { return true }
            return false
        })

        let conversationEntries = filter { entry in
            if case .instructions = entry { return false }
            return true
        }

        #if compiler(>=6.3)
        if #available(iOS 26.4, macOS 26.4, visionOS 26.4, *) {
            return await foundationLabRealTokenBudgetWindow(
                instructions: instructionsEntry,
                conversation: conversationEntries,
                budget: budget,
                model: model
            ) ?? foundationLabEstimatedTokenBudgetWindow(
                instructions: instructionsEntry,
                conversation: conversationEntries,
                budget: budget
            )
        }
        #endif

        return foundationLabEstimatedTokenBudgetWindow(
            instructions: instructionsEntry,
            conversation: conversationEntries,
            budget: budget
        )
    }
}

private func foundationLabEstimateTokens(_ text: String) -> Int {
    guard !text.isEmpty else { return 0 }
    return max(1, Int(ceil(Double(text.count) / 4.5)))
}

private func foundationLabEstimateStructuredTokens(_ content: GeneratedContent) -> Int {
    max(1, Int(ceil(Double(content.jsonString.count) / 4.5)))
}

private extension Transcript {
    func foundationLabEstimatedTokenBudgetWindow(
        instructions: Transcript.Entry?,
        conversation: [Transcript.Entry],
        budget: Int
    ) -> [Transcript.Entry] {
        let base: [Transcript.Entry] = instructions.map { [$0] } ?? []
        var selectedConversation: [Transcript.Entry] = []
        var usedTokens = 0

        if let instructions {
            usedTokens += instructions.foundationLabEstimatedTokenCount
        }

        for entry in conversation.reversed() {
            let entryTokens = entry.foundationLabEstimatedTokenCount
            if usedTokens + entryTokens > budget { break }
            selectedConversation.append(entry)
            usedTokens += entryTokens
        }

        return base + Array(selectedConversation.reversed())
    }

    #if compiler(>=6.3)
    @available(iOS 26.4, macOS 26.4, visionOS 26.4, *)
    func foundationLabRealTokenBudgetWindow(
        instructions: Transcript.Entry?,
        conversation: [Transcript.Entry],
        budget: Int,
        model: SystemLanguageModel
    ) async -> [Transcript.Entry]? {
        let base: [Transcript.Entry] = instructions.map { [$0] } ?? []

        guard let baseTokens = base.isEmpty
            ? 0
            : try? await model.tokenCount(for: base)
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

            guard let tokens = try? await model.tokenCount(for: candidate) else {
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
