import FoundationModels
import Playgrounds
import Foundation

#Playground {
    let session = LanguageModelSession(model: SystemLanguageModel.default)

    let mixedLanguagePrompts = [
        "Hello, mi nombre es Juan. How are you today?",
        "I went to the marché yesterday to buy some pain.",
        "Das ist very interesting, nicht wahr?",
        "Estoy muy tired después de working todo el día."
    ]

    for (index, prompt) in mixedLanguagePrompts.enumerated() {
        do {
            let response = try await session.respond(to: prompt)
            debugPrint("Prompt \(index + 1): \"\(prompt)\"")
            debugPrint("Response: \(response.content)")
        } catch {
            debugPrint("Prompt \(index + 1): Error -> \(error.localizedDescription)")
        }
    }

    do {
        let memoryTest = try await session.respond(to: "What languages have we been mixing in our conversation?")
        debugPrint("Language Memory Test: \(memoryTest.content)")
    } catch {
        debugPrint("Memory test error: \(error.localizedDescription)")
    }
}
