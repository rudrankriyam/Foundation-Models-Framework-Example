import FoundationModels
import FoundationModelsTools
import Testing

@Suite("FoundationModelsTools Compatibility")
struct FoundationModelsKitCompatibilityTests {
    @Test("Tools re-exports FoundationModelsKit utilities")
    func toolsReexportsFoundationModelsKit() {
        #expect(estimateTokens(from: "Foundation Models") > 0)

        let entries: [Transcript.Entry] = [
            .prompt(
                Transcript.Prompt(
                    segments: [.text(Transcript.TextSegment(content: "Latest prompt"))]
                )
            )
        ]

        #expect(entries.rollingWindow(entries: 1) == entries)
    }
}
