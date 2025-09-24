import FoundationModels
import Playgrounds

#Playground {
    let session = LanguageModelSession()

    // Prewarming with prompt prefix caching
    let commonPrefix = Prompt("You are a helpful writing assistant. The user is asking about:")
    session.prewarm(promptPrefix: commonPrefix)

    // Now requests with similar prefixes should be faster
    let fullPrompt = "You are a helpful writing assistant. The user is asking about: grammar rules"
    let response = try await session.respond(to: Prompt(fullPrompt))
    print("Response: \(response.content)")
}
