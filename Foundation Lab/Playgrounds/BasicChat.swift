import FoundationModels
import Playgrounds

#Playground {
  // Create a basic language model session
  let session = LanguageModelSession()

  // List of landmarks to generate bad trip names for
  let landmarks = [
    "Grand Canyon", "Eiffel Tower", "Mount Fuji"
  ]

  // Generate bad trip names for each landmark
  for landmark in landmarks {
    let response = try await session.respond(
      to: "What's a good name for a trip to \(landmark)? Reply only with a title."
    )
  }

  // Example of basic chat with instructions

  let instructedSession = LanguageModelSession(
    instructions: Instructions("You are a helpful assistant that gives creative suggestions.")
  )

  let creativeName = try await instructedSession.respond(
    to: "Suggest a catchy name for a new coffee shop."
  )
}