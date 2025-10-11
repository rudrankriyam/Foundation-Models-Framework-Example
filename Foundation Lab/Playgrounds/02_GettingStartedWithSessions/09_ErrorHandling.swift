import FoundationModels
import Playgrounds
import Foundation

#Playground {
    let session = LanguageModelSession()

    do {
        let result = try await session.respond(to: "Hello, how are you asshole?")
        print("Success: \(result.content)")
    } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
        print("Error: Conversation is too long")
    } catch LanguageModelSession.GenerationError.guardrailViolation {
        print("Error: Content safety system blocked the request")
    } catch LanguageModelSession.GenerationError.assetsUnavailable {
        print("Error: Foundation Models temporarily unavailable")
    } catch LanguageModelSession.GenerationError.concurrentRequests {
        print("Error: Please wait for current request to finish")
    } catch LanguageModelSession.GenerationError.rateLimited {
        print("Error: Too many requests")
    } catch LanguageModelSession.GenerationError.unsupportedLanguageOrLocale {
        print("Error: Language not supported")
    } catch LanguageModelSession.GenerationError.decodingFailure {
        print("Error: Unable to process response")
    } catch LanguageModelSession.GenerationError.unsupportedGuide {
        print("Error: Invalid generation parameters")
    } catch LanguageModelSession.GenerationError.refusal(_, _) {
        print("Error: Model declined to respond")
    } catch {
        print("Error: \(error.localizedDescription)")
    }
}
