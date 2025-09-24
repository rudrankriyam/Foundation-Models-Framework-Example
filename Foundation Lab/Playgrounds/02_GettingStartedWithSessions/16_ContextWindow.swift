import FoundationModels
import Playgrounds

#Playground {
    let session = LanguageModelSession()

    // Build up context with multiple exchanges
    let response1 = try await session.respond(to: "Let's discuss healthy eating habits")
    print("Initial: \(response1.content)")

    let response2 = try await session.respond(to: "What about meal planning?")
    print("Follow-up: \(response2.content)")

    let response3 = try await session.respond(to: "Can you give me a weekly meal plan example?")
    print("Detailed: \(response3.content)")

    // The model remembers the context from previous messages
}
