import FoundationModels
import Playgrounds

#Playground {
    let session = LanguageModelSession()

    // Example 1: Unclear constraints
    let response1 = try await session.respond(to: "Summarize this article")
    print("Unclear: \(response1.content)")

    // Example 2: Clear length constraints
    let response2 = try await session.respond(to: "Summarize this article in exactly two sentences")
    print("Clear constraints: \(response2.content)")
}
