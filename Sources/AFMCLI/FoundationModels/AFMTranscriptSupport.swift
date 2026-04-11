import Foundation
import FoundationModels

extension Transcript.Entry {
    var afmEstimatedTokenCount: Int {
        switch self {
        case .instructions(let instructions):
            instructions.segments.reduce(0) { $0 + $1.afmEstimatedTokenCount }
        case .prompt(let prompt):
            prompt.segments.reduce(0) { $0 + $1.afmEstimatedTokenCount }
        case .response(let response):
            response.segments.reduce(0) { $0 + $1.afmEstimatedTokenCount }
        case .toolCalls(let toolCalls):
            toolCalls.reduce(0) { total, call in
                total + afmEstimateTokens(call.toolName) + afmEstimateStructuredTokens(call.arguments) + 5
            }
        case .toolOutput(let output):
            output.segments.reduce(0) { $0 + $1.afmEstimatedTokenCount } + 3
        @unknown default:
            0
        }
    }

    func afmTokenCount(using model: SystemLanguageModel = .default) async -> Int {
        if #available(macOS 26.4, *) {
            if let realTokenCount = try? await model.tokenCount(for: [self]) {
                return realTokenCount
            }
        }
        return afmEstimatedTokenCount
    }

    func afmTextContent() -> String? {
        switch self {
        case .prompt(let prompt):
            prompt.segments.afmJoinedText()
        case .response(let response):
            response.segments.afmJoinedText()
        case .toolOutput(let toolOutput):
            toolOutput.segments.afmJoinedText()
        default:
            nil
        }
    }
}

extension Transcript.Segment {
    var afmEstimatedTokenCount: Int {
        switch self {
        case .text(let textSegment):
            afmEstimateTokens(textSegment.content)
        case .structure(let structuredSegment):
            afmEstimateStructuredTokens(structuredSegment.content)
        @unknown default:
            0
        }
    }
}

extension Array where Element == Transcript.Segment {
    func afmJoinedText() -> String? {
        let text = compactMap { segment in
            if case .text(let textSegment) = segment {
                return textSegment.content
            }
            return nil
        }.joined(separator: " ")

        return text.isEmpty ? nil : text
    }
}

extension Transcript {
    var afmEstimatedTokenCount: Int {
        reduce(0) { $0 + $1.afmEstimatedTokenCount }
    }

    func afmTokenCount(using model: SystemLanguageModel = .default) async -> Int {
        if #available(macOS 26.4, *) {
            if let realTokenCount = try? await model.tokenCount(for: Array(self)) {
                return realTokenCount
            }
        }
        return afmEstimatedTokenCount
    }

    func afmSafeTokenCount(using model: SystemLanguageModel = .default) async -> Int {
        if #available(macOS 26.4, *) {
            if let realTokens = try? await model.tokenCount(for: Array(self)) {
                let buffer = Int(Double(realTokens) * 0.05)
                return realTokens + buffer
            }
        }

        let baseTokens = afmEstimatedTokenCount
        let buffer = Int(Double(baseTokens) * 0.25)
        return baseTokens + buffer + 100
    }

    func afmIsApproachingLimit(
        threshold: Double = 0.70,
        maxTokens: Int = 4_096,
        using model: SystemLanguageModel = .default
    ) async -> Bool {
        let currentTokens = await afmSafeTokenCount(using: model)
        return currentTokens > Int(Double(maxTokens) * threshold)
    }

    func afmEntriesWithinTokenBudget(
        _ budget: Int,
        using model: SystemLanguageModel = .default
    ) async -> [Transcript.Entry] {
        let instructionsEntry = first {
            if case .instructions = $0 { return true }
            return false
        }
        let conversationEntries = filter { entry in
            if case .instructions = entry { return false }
            return true
        }

        if #available(macOS 26.4, *) {
            return await afmRealTokenBudgetWindow(
                instructions: instructionsEntry,
                conversation: conversationEntries,
                budget: budget,
                model: model
            ) ?? afmEstimatedTokenBudgetWindow(
                instructions: instructionsEntry,
                conversation: conversationEntries,
                budget: budget
            )
        }

        return afmEstimatedTokenBudgetWindow(
            instructions: instructionsEntry,
            conversation: conversationEntries,
            budget: budget
        )
    }

    private func afmEstimatedTokenBudgetWindow(
        instructions: Transcript.Entry?,
        conversation: [Transcript.Entry],
        budget: Int
    ) -> [Transcript.Entry] {
        let base: [Transcript.Entry] = instructions.map { [$0] } ?? []
        var selectedConversation: [Transcript.Entry] = []
        var usedTokens = 0

        if let instructions {
            usedTokens += instructions.afmEstimatedTokenCount
        }

        for entry in conversation.reversed() {
            let entryTokens = entry.afmEstimatedTokenCount
            if usedTokens + entryTokens > budget {
                break
            }
            selectedConversation.append(entry)
            usedTokens += entryTokens
        }

        return base + Array(selectedConversation.reversed())
    }

    @available(macOS 26.4, *)
    private func afmRealTokenBudgetWindow(
        instructions: Transcript.Entry?,
        conversation: [Transcript.Entry],
        budget: Int,
        model: SystemLanguageModel
    ) async -> [Transcript.Entry]? {
        let base: [Transcript.Entry] = instructions.map { [$0] } ?? []
        let baseTokens: Int

        if base.isEmpty {
            baseTokens = 0
        } else if let counted = try? await model.tokenCount(for: base) {
            baseTokens = counted
        } else {
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
}

private func afmEstimateTokens(_ text: String) -> Int {
    guard !text.isEmpty else { return 0 }
    return max(1, Int(ceil(Double(text.count) / 4.5)))
}

private func afmEstimateStructuredTokens(_ content: GeneratedContent) -> Int {
    max(1, Int(ceil(Double(content.jsonString.count) / 4.5)))
}
