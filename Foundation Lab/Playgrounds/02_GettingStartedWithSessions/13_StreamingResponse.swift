import FoundationModels
import Playgrounds

#Playground {
    let session = LanguageModelSession()

    // Stream the response for real-time updates
    let responseStream = session.streamResponse(to: Prompt("Write a short poem about coding"))

    print("Streaming response:")
    for try await partialResponse in responseStream {
        // Each iteration gives you updated content
        print("Partial: \(partialResponse.content)")
    }
}
