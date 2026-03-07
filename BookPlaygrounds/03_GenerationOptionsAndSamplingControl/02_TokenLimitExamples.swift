import FoundationModels
import Playgrounds

#Playground {
    // Short responses for UI cards or notifications
    let briefOptions = GenerationOptions(maximumResponseTokens: 50)

    // Medium responses for chat interfaces
    let chatOptions = GenerationOptions(maximumResponseTokens: 200)

    // Longer responses for content generation
    let detailedOptions = GenerationOptions(maximumResponseTokens: 500)

    let session = LanguageModelSession()
    let prompt = "Explain what artificial intelligence is and how it works."

    debugPrint("Brief Response (50 tokens max)")
    let briefResponse = try await session.respond(to: prompt, options: briefOptions)
    debugPrint("Response: \(briefResponse.content)")
    let briefTokenCount = Int(Double(briefResponse.content.split(separator: " ").count) * 1.3)
    debugPrint("Token count estimate: ~\(briefTokenCount)")

    debugPrint("Chat Response (200 tokens max)")
    let chatResponse = try await session.respond(to: prompt, options: chatOptions)
    debugPrint("Response: \(chatResponse.content)")
    let chatTokenCount = Int(Double(chatResponse.content.split(separator: " ").count) * 1.3)
    debugPrint("Token count estimate: ~\(chatTokenCount)")

    debugPrint("Detailed Response (500 tokens max)")
    let detailedResponse = try await session.respond(to: prompt, options: detailedOptions)
    debugPrint("Response: \(detailedResponse.content)")
    let detailedTokenCount = Int(Double(detailedResponse.content.split(separator: " ").count) * 1.3)
    debugPrint("Token count estimate: ~\(detailedTokenCount)")
}
