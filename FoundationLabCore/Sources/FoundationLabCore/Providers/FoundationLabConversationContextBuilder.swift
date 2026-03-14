import Foundation
import FoundationModels

public enum FoundationLabConversationContextBuilder {
    public static func conversationText(
        from transcript: Transcript,
        userLabel: String,
        assistantLabel: String
    ) -> String {
        transcript.compactMap { entry in
            switch entry {
            case .prompt:
                guard let text = entry.textContent() else { return nil }
                return "\(userLabel) \(text)"
            case .response:
                guard let text = entry.textContent() else { return nil }
                return "\(assistantLabel) \(text)"
            default:
                return nil
            }
        }
        .joined(separator: "\n\n")
    }

    public static func contextInstructions(
        baseInstructions: String,
        summary: FoundationLabConversationSummary,
        continuationNote: String? = nil
    ) -> String {
        var contextInstructions = """
        \(baseInstructions)

        You are continuing a conversation with a user. Here's a summary of your previous conversation:

        CONVERSATION SUMMARY:
        \(summary.summary)

        KEY TOPICS DISCUSSED:
        \(summary.keyTopics.foundationLabBulletList())

        USER PREFERENCES/REQUESTS:
        \(summary.userPreferences.foundationLabBulletList())
        """

        if let continuationNote, !continuationNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            contextInstructions += "\n\n\(continuationNote)"
        }

        return contextInstructions
    }
}

extension Array where Element == Transcript.Segment {
    func foundationLabTextContentJoined() -> String? {
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

extension Transcript.Entry {
    func textContent() -> String? {
        switch self {
        case .prompt(let prompt):
            return prompt.segments.foundationLabTextContentJoined()
        case .response(let response):
            return response.segments.foundationLabTextContentJoined()
        case .toolOutput(let toolOutput):
            return toolOutput.segments.foundationLabTextContentJoined()
        default:
            return nil
        }
    }
}

private extension Array where Element == String {
    func foundationLabBulletList(prefix: String = "• ") -> String {
        guard !isEmpty else { return "\(prefix)None recorded yet" }
        return map { "\(prefix)\($0)" }.joined(separator: "\n")
    }
}
