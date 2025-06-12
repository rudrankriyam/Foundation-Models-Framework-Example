import FoundationModels
import Playgrounds

#Playground {
  let session = LanguageModelSession()

  print("Starting streaming response example...")

  let stream = session.streamResponse(to: "Write a short poem about technology and innovation.")

  for try await partialResult in stream {
    print("Partial response: \(partialResult)")
  }

  print("Streaming complete")
}
