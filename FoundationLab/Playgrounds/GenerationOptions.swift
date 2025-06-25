import FoundationModels
import Playgrounds

#Playground {
  let session = LanguageModelSession()
  let prompt = "Write a short poem about the ocean."

  print("Exploring Different Generation Options")
  print("Prompt: '\(prompt)'\n")

  print("1. GREEDY SAMPLING (Deterministic) - Always chooses the most likely token")
  let greedyResponse = try await session.respond(
    to: prompt,
    options: GenerationOptions(sampling: .greedy)
  )
  print("Greedy Response:")
  print(greedyResponse.content)
  print("\n" + String(repeating: "=", count: 50) + "\n")

  print("2. TEMPERATURE VARIATIONS - Temperature controls creativity vs consistency")

  print("Low Temperature (0.3) - More focused and consistent:")
  let lowTempResponse = try await session.respond(
    to: prompt,
    options: GenerationOptions(temperature: 0.3)
  )
  print(lowTempResponse.content)

  print("Medium Temperature (0.7) - Balanced creativity:")
  let mediumTempResponse = try await session.respond(
    to: prompt,
    options: GenerationOptions(temperature: 0.7)
  )
  print(mediumTempResponse.content)

  print("High Temperature (1.5) - More creative and varied:")
  let highTempResponse = try await session.respond(
    to: prompt,
    options: GenerationOptions(temperature: 1.5)
  )
  print(highTempResponse.content)
  print("\n" + String(repeating: "=", count: 50) + "\n")

  print("3. TOP-K SAMPLING - Considers only the top K most probable tokens")

  print("Top-5 Sampling (Very focused):")
  let topKResponse = try await session.respond(
    to: prompt,
    options: GenerationOptions(sampling: .random(top: 5, seed: 12345))
  )
  print(topKResponse.content)

  print("Top-50 Sampling (More diverse):")
  let topK50Response = try await session.respond(
    to: prompt,
    options: GenerationOptions(sampling: .random(top: 50, seed: 67890))
  )
  print(topK50Response.content)
  print("\n" + String(repeating: "=", count: 50) + "\n")

  print(
    "4. NUCLEUS (TOP-P) SAMPLING - Considers tokens until cumulative probability reaches threshold")

  print("Conservative Nucleus (p=0.3):")
  let conservativeNucleusResponse = try await session.respond(
    to: prompt,
    options: GenerationOptions(sampling: .random(probabilityThreshold: 0.3, seed: 11111))
  )
  print(conservativeNucleusResponse.content)

  print("Balanced Nucleus (p=0.9):")
  let balancedNucleusResponse = try await session.respond(
    to: prompt,
    options: GenerationOptions(sampling: .random(probabilityThreshold: 0.9, seed: 22222))
  )
  print(balancedNucleusResponse.content)
  print("\n" + String(repeating: "=", count: 50) + "\n")

  print("5. MAXIMUM RESPONSE TOKENS - Controlling response length")

  print("Short Response (max 20 tokens):")
  let shortResponse = try await session.respond(
    to: "Tell me about artificial intelligence and its applications in modern society.",
    options: GenerationOptions(maximumResponseTokens: 20)
  )
  print(shortResponse.content)

  print("Medium Response (max 100 tokens):")
  let mediumResponse = try await session.respond(
    to: "Tell me about artificial intelligence and its applications in modern society.",
    options: GenerationOptions(maximumResponseTokens: 100)
  )
  print(mediumResponse.content)
  print("\n" + String(repeating: "=", count: 50) + "\n")
}
