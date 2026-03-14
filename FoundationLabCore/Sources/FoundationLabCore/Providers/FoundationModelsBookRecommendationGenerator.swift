import Foundation
import FoundationModels

public struct FoundationModelsBookRecommendationGenerator: BookRecommendationGenerating {
    public init() {}

    public func generateBookRecommendation(
        for request: GenerateBookRecommendationRequest
    ) async throws -> GenerateBookRecommendationResult {
        let trimmedPrompt = request.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing prompt")
        }

        let session: LanguageModelSession
        if let systemPrompt = request.systemPrompt?.trimmingCharacters(in: .whitespacesAndNewlines),
           !systemPrompt.isEmpty {
            session = LanguageModelSession(instructions: Instructions(systemPrompt))
        } else {
            session = LanguageModelSession()
        }

        let response = try await session.respond(
            to: Prompt(trimmedPrompt),
            generating: BookRecommendation.self
        )

        let tokenCount = await session.transcript.foundationLabTokenCount()

        return GenerateBookRecommendationResult(
            recommendation: response.content,
            metadata: CapabilityExecutionMetadata(
                provider: "Foundation Models",
                tokenCount: tokenCount
            )
        )
    }
}

private extension Transcript.Entry {
    var foundationLabEstimatedTokenCount: Int {
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

private extension Transcript.Segment {
    var foundationLabEstimatedTokenCount: Int {
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

private extension Transcript {
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
}

private func foundationLabEstimateTokens(_ text: String) -> Int {
    guard !text.isEmpty else { return 0 }
    return max(1, Int(ceil(Double(text.count) / 4.5)))
}

private func foundationLabEstimateStructuredTokens(_ content: GeneratedContent) -> Int {
    max(1, Int(ceil(Double(content.jsonString.count) / 4.5)))
}
