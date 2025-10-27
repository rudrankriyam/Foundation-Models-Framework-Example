import FoundationModels
import Playgrounds

#Playground {
    let customInstructions = Instructions("""
    You are a professional writing coach.
    Help users improve their writing by focusing on:
    - Clarity and conciseness
    - Strong word choice
    - Logical structure
    - Engaging tone

    Provide specific, actionable feedback.
    Be encouraging and constructive.
    """)

    let session = LanguageModelSession(instructions: customInstructions)
    let response = try await session.respond(to: "Please review this sentence: 'The quick brown fox jumps over " +
                                                    "the lazy dog.'")
    print("Feedback: \(response.content)")
}
