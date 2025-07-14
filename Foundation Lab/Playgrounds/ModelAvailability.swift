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
        print(response.content)
    } else {
        print("Foundation Models is not available on this device")
        print("This feature requires:")
        print("- macOS 15.0+ or iOS 18.0+")
        print("- Compatible Apple Silicon or Neural Engine")
    }
}
