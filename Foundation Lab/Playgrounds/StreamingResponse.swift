import FoundationModels
import Playgrounds

#Playground {
  // Create a basic language model session
  let session = LanguageModelSession()

  print("Starting streaming response example...")

  // Create a streaming response
  let stream = session.streamResponse(to: "Write a haiku about destiny.")

  print("\nStreaming poem content:")

  // Process each partial response as it arrives
  for try await partialResult in stream {
    print("Partial response: \(partialResult)")
  }

  print("\nStreaming complete")

  // Example 2: Streaming with instructions
  print("\n--- Streaming with Instructions ---")

  let instructedSession = LanguageModelSession(
    instructions: Instructions("You are a creative writer who writes in a poetic style.")
  )

  let poeticStream = instructedSession.streamResponse(
    to: "Describe a sunset over the ocean in 3 sentences."
  )

  print("\nStreaming poetic description:")

  for try await partialResult in poeticStream {
    print("\(partialResult)")
  }

  // You can also collect the final response if needed
  let finalResponse = try await poeticStream.collect()
  print("\nFinal collected response:")
  print(finalResponse.content)

  // Example 3: Streaming a longer response
  print("\n--- Streaming Longer Content ---")

  let storyStream = session.streamResponse(
    to: "Write a short story about a robot learning to paint. Make it about 200 words."
  )

  print("\nStreaming robot story:")

  for try await partialResult in storyStream {
    // In a real app, you might update UI here
    print("Story chunk: \(partialResult)")
  }

  print("\nStory streaming complete!")
}
