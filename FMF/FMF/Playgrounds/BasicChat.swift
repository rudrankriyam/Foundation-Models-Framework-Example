import FoundationModels
import Playgrounds

#Playground {
  let session = LanguageModelSession()
  let landmarks = ["Grand Canyon", "Eiffel Tower", "Mount Fuji", "Great Wall of China", "Sydney Opera House"]
  
  for landmark in landmarks {
    let response = try await session.respond(
      to: "What's a bad name for a trip to \(landmark)? Reply only with a title."
    )
    print("\(landmark): \(response.content)")
  }
}
