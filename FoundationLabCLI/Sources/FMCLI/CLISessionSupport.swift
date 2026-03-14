import ArgumentParser
import Foundation
import FoundationLabCore
import FoundationModels

enum CLISamplingMode: String, CaseIterable, ExpressibleByArgument {
    case greedy
    case topK = "top-k"
    case nucleus
}

enum CLIFeedbackSentiment: String, CaseIterable, ExpressibleByArgument {
    case positive
    case negative

    var foundationModelsValue: LanguageModelFeedback.Sentiment {
        switch self {
        case .positive:
            .positive
        case .negative:
            .negative
        }
    }
}

struct CLIGenerationParameters: ParsableArguments {
    @Option(name: .long, help: "Optional system instructions for the session.")
    var systemPrompt: String?

    @Option(name: .long, help: "Sampling mode to use.")
    var samplingMode: CLISamplingMode?

    @Option(name: .customLong("temperature"), help: "Sampling temperature.")
    var temperature: Double?

    @Option(name: .customLong("top-k"), help: "Top-K value when using top-k sampling.")
    var topK = 50

    @Option(name: .customLong("top-p"), help: "Probability threshold when using nucleus sampling.")
    var topP = 0.9

    @Option(name: .customLong("max-tokens"), help: "Maximum response tokens.")
    var maximumResponseTokens: Int?

    func foundationLabValue() -> FoundationLabGenerationOptions? {
        let sampling: FoundationLabGenerationOptions.SamplingMode? = switch samplingMode {
        case .greedy:
            .greedy
        case .topK:
            .randomTop(topK)
        case .nucleus:
            .randomProbabilityThreshold(topP)
        case .none:
            nil
        }

        guard sampling != nil || temperature != nil || maximumResponseTokens != nil else {
            return nil
        }

        return FoundationLabGenerationOptions(
            sampling: sampling,
            temperature: temperature,
            maximumResponseTokens: maximumResponseTokens
        )
    }
}

struct CLISessionOutputOptions: ParsableArguments {
    @Flag(
        name: [.customLong("transcript"), .customLong("include-transcript")],
        help: "Include the session transcript in the output."
    )
    var includeTranscript = false

    @Option(
        name: [.customLong("log-feedback"), .customLong("feedback")],
        help: "Attach model feedback to the assistant response."
    )
    var feedback: CLIFeedbackSentiment?
}

func makeConversationEngine(systemPrompt: String?) async -> FoundationLabConversationEngine {
    await MainActor.run {
        FoundationLabConversationEngine(
            configuration: cliConversationConfiguration(systemPrompt: systemPrompt)
        )
    }
}

func sessionMetrics(
    from engine: FoundationLabConversationEngine
) async -> (sessionCount: Int, tokenCount: Int) {
    await MainActor.run {
        (engine.sessionCount, engine.currentTokenCount)
    }
}

func sessionTranscriptSnapshot(
    from engine: FoundationLabConversationEngine,
    includeTranscript: Bool
) async -> (payload: [[String: String]]?, text: String?) {
    await MainActor.run {
        guard includeTranscript else {
            return (nil, nil)
        }

        let transcript = engine.session.transcript
        return (
            cliSessionTranscriptPayload(transcript),
            cliSessionTranscriptText(transcript)
        )
    }
}

func cliSessionTranscriptPayload(_ transcript: Transcript) -> [[String: String]] {
    transcript.compactMap { entry in
        switch entry {
        case .prompt(let prompt):
            guard let content = prompt.segments.cliTranscriptTextContent() else { return nil }
            return [
                "role": "user",
                "content": content
            ]
        case .response(let response):
            guard let content = response.segments.cliTranscriptTextContent() else { return nil }
            return [
                "role": "assistant",
                "content": content
            ]
        case .toolOutput(let toolOutput):
            guard let content = toolOutput.segments.cliTranscriptTextContent() else { return nil }
            return [
                "role": "tool",
                "content": content
            ]
        default:
            return nil
        }
    }
}

func cliSessionTranscriptText(_ transcript: Transcript) -> String {
    cliSessionTranscriptPayload(transcript)
        .map { entry in
            let role = (entry["role"] as? String ?? "unknown").capitalized
            let content = entry["content"] as? String ?? ""
            return "\(role): \(content)"
        }
        .joined(separator: "\n\n")
}

@discardableResult
func applySessionFeedback(
    _ feedback: CLIFeedbackSentiment?,
    to session: LanguageModelSession
) -> String? {
    guard let feedback else { return nil }
    _ = session.logFeedbackAttachment(sentiment: feedback.foundationModelsValue)
    return feedback.rawValue
}

func logSessionFeedback(
    _ feedback: CLIFeedbackSentiment?,
    on engine: FoundationLabConversationEngine
) async -> String? {
    await MainActor.run {
        applySessionFeedback(feedback, to: engine.session)
    }
}

func sessionGenerationPayload(
    _ parameters: CLIGenerationParameters
) -> [String: Any] {
    [
        "systemPrompt": parameters.systemPrompt ?? "",
        "samplingMode": parameters.samplingMode?.rawValue ?? "",
        "temperature": parameters.temperature as Any,
        "topK": parameters.samplingMode == .topK ? parameters.topK : NSNull(),
        "topP": parameters.samplingMode == .nucleus ? parameters.topP : NSNull(),
        "maximumResponseTokens": parameters.maximumResponseTokens as Any
    ]
}

func humanReadableSessionResponse(
    response: String,
    transcriptText: String?,
    sessionCount: Int,
    tokenCount: Int,
    feedback: String?,
    verbose: Bool,
    streamed: Bool
) -> String {
    var lines: [String] = []

    if !streamed {
        lines.append(response)
    }

    if let feedback {
        if !lines.isEmpty {
            lines.append("")
        }
        lines.append("Feedback logged: \(feedback)")
    }

    if let transcriptText, !transcriptText.isEmpty {
        if !lines.isEmpty {
            lines.append("")
        }
        lines.append("Transcript")
        lines.append(transcriptText)
    }

    if verbose {
        if !lines.isEmpty {
            lines.append("")
        }
        lines.append("Sessions: \(sessionCount)")
        lines.append("Token count: \(tokenCount)")
    }

    return lines.joined(separator: "\n")
}

func humanReadableSessionConversation(
    exchanges: [[String: String]],
    transcriptText: String?,
    sessionCount: Int,
    tokenCount: Int,
    feedback: String?,
    verbose: Bool,
    streamed: Bool
) -> String {
    var lines: [String] = []

    if !streamed {
        for exchange in exchanges {
            lines.append("User: \(exchange["message"] ?? "")")
            lines.append("Assistant: \(exchange["response"] ?? "")")
            lines.append("")
        }

        if !lines.isEmpty {
            lines.removeLast()
        }
    }

    if let feedback {
        if !lines.isEmpty {
            lines.append("")
        }
        lines.append("Feedback logged: \(feedback)")
    }

    if let transcriptText, !transcriptText.isEmpty {
        if !lines.isEmpty {
            lines.append("")
        }
        lines.append("Transcript")
        lines.append(transcriptText)
    }

    if verbose {
        if !lines.isEmpty {
            lines.append("")
        }
        lines.append("Sessions: \(sessionCount)")
        lines.append("Token count: \(tokenCount)")
    }

    return lines.joined(separator: "\n")
}

private extension Array where Element == Transcript.Segment {
    func cliTranscriptTextContent() -> String? {
        let text = compactMap { segment in
            if case .text(let textSegment) = segment {
                return textSegment.content
            }
            return nil
        }
        .joined(separator: " ")

        return text.isEmpty ? nil : text
    }
}
