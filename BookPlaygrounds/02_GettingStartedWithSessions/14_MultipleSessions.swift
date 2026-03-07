import FoundationModels
import Playgrounds

#Playground {
    // Single-turn sessions (independent)
    let session1 = LanguageModelSession()
    let titleResponse = try await session1.respond(to: "Generate a creative title for a blog about technology")
    print("Title: \(titleResponse.content)")

    // Fresh session for unrelated task
    let session2 = LanguageModelSession()
    let summaryResponse = try await session2.respond(to: "Summarize the benefits of meditation in 3 bullet points")
    print("Summary: \(summaryResponse.content)")
}
