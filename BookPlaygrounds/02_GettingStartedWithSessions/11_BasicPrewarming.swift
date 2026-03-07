import FoundationModels
import Playgrounds

#Playground {
    let session = LanguageModelSession()

    // Basic prewarming - loads model resources into memory
    session.prewarm()

    // Now make a request - should be faster
    let response = try await session.respond(to: "What is the capital of France?")
    print("Response: \(response.content)")
}
