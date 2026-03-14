import Foundation
import FoundationModels

extension Transcript.Entry {
    fileprivate var foundationLabEstimatedTokenCount: Int {
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
    fileprivate var foundationLabEstimatedTokenCount: Int {
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

extension Transcript {
    fileprivate var foundationLabEstimatedTokenCount: Int {
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
}

private func foundationLabEstimateTokens(_ text: String) -> Int {
    guard !text.isEmpty else { return 0 }
    return max(1, Int(ceil(Double(text.count) / 4.5)))
}

private func foundationLabEstimateStructuredTokens(_ content: GeneratedContent) -> Int {
    max(1, Int(ceil(Double(content.jsonString.count) / 4.5)))
}
