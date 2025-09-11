import FoundationModels
import Playgrounds

#Playground {
  let session = LanguageModelSession()
  let prompt = "Write a short poem about the ocean."


  let greedyResponse = try await session.respond(
    to: prompt,
    options: GenerationOptions(sampling: .greedy)
  )
  debugPrint("1. GREEDY SAMPLING - Always picks most likely token\n\(greedyResponse.content)")


  let lowTempResponse = try await session.respond(
    to: prompt,
    options: GenerationOptions(temperature: 0.3)
  )
  debugPrint("2. LOW TEMPERATURE (0.3) - More focused and deterministic\n\(lowTempResponse.content)")

  let mediumTempResponse = try await session.respond(
    to: prompt,
    options: GenerationOptions(temperature: 0.7)
  )
  debugPrint("3. MEDIUM TEMPERATURE (0.7) - Balanced creativity\n\(mediumTempResponse.content)")

  let highTempResponse = try await session.respond(
    to: prompt,
    options: GenerationOptions(temperature: 1.5)
  )
  debugPrint("4. HIGH TEMPERATURE (1.5) - More creative and varied\n\(highTempResponse.content)")


  let topKResponse = try await session.respond(
    to: prompt,
    options: GenerationOptions(sampling: .random(top: 5, seed: 12345))
  )
  debugPrint("5. TOP-K (5) SAMPLING - Considers only top 5 most likely tokens\n\(topKResponse.content)")

  let topK50Response = try await session.respond(
    to: prompt,
    options: GenerationOptions(sampling: .random(top: 50, seed: 67890))
  )
  debugPrint("6. TOP-K (50) SAMPLING - Considers top 50 most likely tokens\n\(topK50Response.content)")

  let conservativeNucleusResponse = try await session.respond(
    to: prompt,
    options: GenerationOptions(sampling: .random(probabilityThreshold: 0.3, seed: 11111))
  )
  debugPrint("7. CONSERVATIVE NUCLEUS (0.3) - Focused on high probability tokens\n\(conservativeNucleusResponse.content)")

  let balancedNucleusResponse = try await session.respond(
    to: prompt,
    options: GenerationOptions(sampling: .random(probabilityThreshold: 0.9, seed: 22222))
  )
  debugPrint("8. BALANCED NUCLEUS (0.9) - Includes more diverse tokens\n\(balancedNucleusResponse.content)")


  let shortResponse = try await session.respond(
    to: "Tell me about artificial intelligence and its applications in modern society.",
    options: GenerationOptions(maximumResponseTokens: 20)
  )
  debugPrint("9. SHORT RESPONSE (20 tokens max): \(shortResponse.content)")

  let mediumResponse = try await session.respond(
    to: "Tell me about artificial intelligence and its applications in modern society.",
    options: GenerationOptions(maximumResponseTokens: 100)
  )
  debugPrint("10. MEDIUM RESPONSE (100 tokens max): \(mediumResponse.content)")
}
