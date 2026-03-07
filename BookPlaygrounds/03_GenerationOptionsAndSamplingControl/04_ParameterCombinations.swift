import FoundationModels
import Playgrounds

#Playground {
    // Content summarization with focused and concise responses
    let summaryOptions = GenerationOptions(
        temperature: 0.2,
        maximumResponseTokens: 150
    )

    // Creative writing with more varied and expressive responses
    let storyOptions = GenerationOptions(
        temperature: 0.9,
        maximumResponseTokens: 400
    )

    // Technical assistance with precise and reliable responses
    let technicalOptions = GenerationOptions(
        temperature: 0.1,
        maximumResponseTokens: 300
    )

    // Casual conversation with natural and engaging responses
    let chatOptions = GenerationOptions(
        temperature: 0.7,
        maximumResponseTokens: 200
    )

    let session = LanguageModelSession()

    // Summary example
    debugPrint("Content Summarization (Temp: 0.2, Tokens: 150)")
    let summaryPrompt = "Summarize the key benefits of regular exercise in a few sentences."
    let summaryResponse = try await session.respond(to: summaryPrompt, options: summaryOptions)
    debugPrint("Response: \(summaryResponse.content)")

    // Creative writing example
    debugPrint("Creative Writing (Temp: 0.9, Tokens: 400)")
    let storyPrompt = "Write a short story about a robot learning to paint"
    let storyResponse = try await session.respond(to: storyPrompt, options: storyOptions)
    debugPrint("Response: \(storyResponse.content)")

    // Technical assistance example
    debugPrint("Technical Assistance (Temp: 0.1, Tokens: 300)")
    let technicalPrompt = "Explain how to implement a binary search algorithm in Swift"
    let technicalResponse = try await session.respond(to: technicalPrompt, options: technicalOptions)
    debugPrint("Response: \(technicalResponse.content)")

    // Chat example
    debugPrint("Casual Conversation (Temp: 0.7, Tokens: 200)")
    let chatPrompt = "What's your favorite thing about autumn weather?"
    let chatResponse = try await session.respond(to: chatPrompt, options: chatOptions)
    debugPrint("Response: \(chatResponse.content)")
}
