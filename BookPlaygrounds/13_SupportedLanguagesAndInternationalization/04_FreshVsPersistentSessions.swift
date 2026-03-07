import FoundationModels
import Playgrounds
import Foundation

#Playground {
    do {
        let freshSession1 = LanguageModelSession()
        let englishResponse = try await freshSession1.respond(to: "Hello, how are you?")
        debugPrint("Fresh Session English: \(englishResponse.content)")

        let freshSession2 = LanguageModelSession()
        let spanishResponse = try await freshSession2.respond(to: "Hola, ¿cómo estás?")
        debugPrint("Fresh Session Spanish: \(spanishResponse.content)")
    } catch {
        debugPrint("Fresh session error: \(error.localizedDescription)")
    }

    do {
        let persistentSession = LanguageModelSession(model: SystemLanguageModel.default)

        let english = try await persistentSession.respond(to: "Hello, how are you?")
        debugPrint("Persistent English: \(english.content)")

        let spanish = try await persistentSession.respond(to: "Hola, ¿cómo estás?")
        debugPrint("Persistent Spanish: \(spanish.content)")

        let switchBack = try await persistentSession.respond(to: "Now answer in English please")
        debugPrint("Language Switch: \(switchBack.content)")

        let memory = try await persistentSession.respond(to: "What language did I first speak to you in?")
        debugPrint("Context Memory: \(memory.content)")

    } catch {
        debugPrint("Persistent session error: \(error.localizedDescription)")
    }
}
