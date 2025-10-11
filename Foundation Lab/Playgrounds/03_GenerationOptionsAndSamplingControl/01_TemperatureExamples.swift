import FoundationModels
import Playgrounds

#Playground {
    // Temperature: 0.1 - Very predictable, focused responses
    let preciseOptions = GenerationOptions(temperature: 0.1)

    // Temperature: 0.7 - Balanced creativity and coherence
    let balancedOptions = GenerationOptions(temperature: 0.7)

    // Temperature: 1.0 - Maximum creativity within bounds
    let creativeOptions = GenerationOptions(temperature: 1.0)

    // System default - Let Foundation Models choose optimal temperature
    let defaultOptions = GenerationOptions(temperature: nil)

    let session = LanguageModelSession()
    let prompt = "Describe the color blue in three words."

    debugPrint("Temperature 0.1 (Very Predictable)")
    let preciseResponse = try await session.respond(to: prompt, options: preciseOptions)
    debugPrint("Response: \(preciseResponse.content)")

    debugPrint("Temperature 0.7 (Balanced)")
    let balancedResponse = try await session.respond(to: prompt, options: balancedOptions)
    debugPrint("Response: \(balancedResponse.content)")

    debugPrint("Temperature 1.0 (Maximum Creativity)")
    let creativeResponse = try await session.respond(to: prompt, options: creativeOptions)
    debugPrint("Response: \(creativeResponse.content)")

    debugPrint("System Default Temperature")
    let defaultResponse = try await session.respond(to: prompt, options: defaultOptions)
    debugPrint("Response: \(defaultResponse.content)")
}
