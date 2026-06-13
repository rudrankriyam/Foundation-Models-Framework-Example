import FoundationModels

public extension Array where Element == Transcript.Segment {
    func joinedTextContent() -> String? {
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
