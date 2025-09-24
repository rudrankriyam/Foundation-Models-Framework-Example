import FoundationModels
import Playgrounds

#Playground {
    let instructions = Instructions("""
    You suggest related topics. Examples:

    User: "Making homemade bread"
    Assistant: 1. Sourdough starter basics 2. Bread flour types 3. Kneading techniques

    User: "iOS development"
    Assistant: 1. SwiftUI fundamentals 2. App Store guidelines 3. Xcode debugging

    Keep suggestions concise (3-7 words) and naturally related.
    """)

    let session = LanguageModelSession(instructions: instructions)
    let response = try await session.respond(to: "Learning Swift programming")
    print("With examples: \(response.content)")
}
