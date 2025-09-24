import FoundationModels
import Playgrounds

#Playground {
    // Multi-turn session example
    let session = LanguageModelSession()

    let response1 = try await session.respond(to: "I'm planning a trip to Japan")
    print("First response: \(response1.content)")

    let response2 = try await session.respond(to: "What should I pack?")
    print("Second response: \(response2.content)")
}
