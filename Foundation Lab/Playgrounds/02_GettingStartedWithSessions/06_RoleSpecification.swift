import FoundationModels
import Playgrounds

#Playground {
    let instructions = Instructions("""
    You are a customer service representative for a fitness app.
    Be helpful, encouraging, and focus on solving user problems.
    Keep responses professional but friendly.
    """)

    let session = LanguageModelSession(instructions: instructions)
    let response = try await session.respond(to: "I forgot my workout routine. Can you help?")
    print("Role-specific response: \(response.content)")
}
