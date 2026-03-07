import FoundationModels
import Playgrounds

#Playground {
    // Single-turn session example
    let session = LanguageModelSession()
    let response = try await session.respond(to: "Generate a title for a travel blog")
    print("Response: \(response.content)")
}
