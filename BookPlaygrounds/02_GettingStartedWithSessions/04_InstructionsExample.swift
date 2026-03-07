import FoundationModels
import Playgrounds

#Playground {
    // Session with instructions
    let instructions = Instructions("You are a helpful assistant. Keep responses concise.")

    let session = LanguageModelSession(instructions: instructions)
    let response = try await session.respond(to: "What are the benefits of exercise?")
    print("Response: \(response.content)")
}
