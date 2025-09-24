import FoundationModels
import Playgrounds
import Foundation

#Playground {
    // Generate responses in different languages by prompting in that language
    struct LanguagePrompt {
        let name: String
        let text: String
    }

    let session = LanguageModelSession(model: SystemLanguageModel.default)

    let prompts: [LanguagePrompt] = [
        .init(name: "English", text: "What is the capital of France? Please provide a brief answer."),
        .init(name: "Spanish", text: "¿Cuál es la capital de España? Por favor, proporciona una respuesta breve."),
        .init(name: "French", text: "Quelle est la capitale de l'Allemagne ? Veuillez donner une réponse brève."),
        .init(name: "German", text: "Was ist die Hauptstadt von Italien? Bitte geben Sie eine kurze Antwort."),
        .init(name: "Italian", text: "Qual è la capitale del Portogallo? Per favore, fornisci una risposta breve."),
        .init(name: "Portuguese", text: "Qual é a capital do Brasil? Por favor, forneça uma resposta breve."),
        .init(name: "Chinese", text: "中国的首都是什么？请简要回答。"),
        .init(name: "Japanese", text: "日本の首都は何ですか？簡潔にお答えください。"),
        .init(name: "Korean", text: "한국의 수도는 어디인가요? 간단히 답해주세요.")
    ]

    for prompt in prompts {
        do {
            let response = try await session.respond(to: prompt.text)
            debugPrint("\(prompt.name): \(response.content)")
        } catch {
            debugPrint("\(prompt.name): Error -> \(error.localizedDescription)")
        }
    }
}
