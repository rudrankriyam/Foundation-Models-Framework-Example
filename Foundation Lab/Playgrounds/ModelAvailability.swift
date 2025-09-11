import FoundationModels
import Playgrounds

#Playground {
    let availability = SystemLanguageModel.default.availability
    let isAvailable = availability == .available

    if isAvailable {
        let session = LanguageModelSession()

        let response = try await session.respond(
            to: "Say 'Hello from Foundation Models!' in a creative way."
        )
    } else {
    }
}
