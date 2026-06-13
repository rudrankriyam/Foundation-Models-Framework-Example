import FoundationModels
import Testing
@testable import FoundationModelsKit

@Suite("Transcript Text Content Tests")
struct TranscriptTextContentTests {
    @Test("Text segments join with spaces")
    func textSegmentsJoinWithSpaces() {
        let segments: [Transcript.Segment] = [
            .text(.init(content: "Hello")),
            .text(.init(content: "Foundation Models"))
        ]

        #expect(segments.joinedTextContent() == "Hello Foundation Models")
    }

    @Test("Segments without text return nil")
    func segmentsWithoutTextReturnNil() {
        let segments: [Transcript.Segment] = []

        #expect(segments.joinedTextContent() == nil)
    }
}
