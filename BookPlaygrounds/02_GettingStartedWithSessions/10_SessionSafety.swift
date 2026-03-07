import FoundationModels
import Playgrounds

#Playground {
    let session = LanguageModelSession()

    // Check if session is responding before making requests
    guard !session.isResponding else {
        print("Session is busy")
        return
    }

    let response = try await session.respond(to: "Tell me a joke")
    print("Response: \(response.content)")
}
