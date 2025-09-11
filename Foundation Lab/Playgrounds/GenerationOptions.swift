import FoundationModels
import Playgrounds

#Playground {
  let session = LanguageModelSession()
  let prompt = "Write a short poem about the ocean."


  let greedyResponse = try await session.respond(
    to: prompt,
    options: GenerationOptions(sampling: .greedy)
  )


  let lowTempResponse = try await session.respond(
    to: prompt,
    options: GenerationOptions(temperature: 0.3)
  )

  let mediumTempResponse = try await session.respond(
    to: prompt,
    options: GenerationOptions(temperature: 0.7)
  )

  let highTempResponse = try await session.respond(
    to: prompt,
    options: GenerationOptions(temperature: 1.5)
  )


  let topKResponse = try await session.respond(
    to: prompt,
    options: GenerationOptions(sampling: .random(top: 5, seed: 12345))
  )

  let topK50Response = try await session.respond(
    to: prompt,
    options: GenerationOptions(sampling: .random(top: 50, seed: 67890))
  )

    "4. NUCLEUS (TOP-P) SAMPLING - Considers tokens until cumulative probability reaches threshold")

  let conservativeNucleusResponse = try await session.respond(
    to: prompt,
    options: GenerationOptions(sampling: .random(probabilityThreshold: 0.3, seed: 11111))
  )

  let balancedNucleusResponse = try await session.respond(
    to: prompt,
    options: GenerationOptions(sampling: .random(probabilityThreshold: 0.9, seed: 22222))
  )


  let shortResponse = try await session.respond(
    to: "Tell me about artificial intelligence and its applications in modern society.",
    options: GenerationOptions(maximumResponseTokens: 20)
  )

  let mediumResponse = try await session.respond(
    to: "Tell me about artificial intelligence and its applications in modern society.",
    options: GenerationOptions(maximumResponseTokens: 100)
  )
}
