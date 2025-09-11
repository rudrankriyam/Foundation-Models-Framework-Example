import FoundationModels
import Playgrounds

#Playground {
  // Create a basic language model session
  let session = LanguageModelSession()


  // Create a streaming response
  let stream = session.streamResponse(to: "Write a haiku about destiny.")


  // Process each partial response as it arrives
  for try await partialResult in stream {
  }


  // Example 2: Streaming with instructions

  let instructedSession = LanguageModelSession(
    instructions: Instructions("You are a creative writer who writes in a poetic style.")
  )

  let poeticStream = instructedSession.streamResponse(
    to: "Describe a sunset over the ocean in 3 sentences."
  )


  for try await partialResult in poeticStream {
  }

  // You can also collect the final response if needed
  let finalResponse = try await poeticStream.collect()

  // Example 3: Streaming a longer response

  let storyStream = session.streamResponse(
    to: "Write a short story about a robot learning to paint. Make it about 200 words."
  )


  for try await partialResult in storyStream {
    // In a real app, you might update UI here
  }

}
