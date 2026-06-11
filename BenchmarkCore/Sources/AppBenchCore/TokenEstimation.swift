import Foundation
import FoundationModels

private let inputCharactersPerToken = 1057.0 / 235.0
private let outputCharactersPerToken = 13680.0 / 2276.0

func estimateInputTokens(_ text: String) -> Int {
    estimateTokens(text, charactersPerToken: inputCharactersPerToken)
}

func estimateOutputTokens(_ text: String) -> Int {
    estimateTokens(text, charactersPerToken: outputCharactersPerToken)
}

func renderText(from snapshot: LanguageModelSession.ResponseStream<String>.Snapshot) -> String {
    if let value = try? snapshot.rawContent.value(String.self) {
        return value
    }
    return snapshot.rawContent.jsonString
}

func renderStructured(
    from snapshot: LanguageModelSession.ResponseStream<GeneratedContent>.Snapshot
) -> String {
    snapshot.rawContent.jsonString
}

private func estimateTokens(_ text: String, charactersPerToken: Double) -> Int {
    guard !text.isEmpty else { return 0 }
    return max(1, Int(ceil(Double(text.count) / charactersPerToken)))
}
