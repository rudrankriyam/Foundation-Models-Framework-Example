import FoundationModels
import Playgrounds

#Playground {
  let session = LanguageModelSession(tools: [WeatherTool()])

  print("Asking about weather in multiple cities...")

  let response = try await session.respond(
    to: "What's the weather like in Boston, Wichita, and Pittsburgh? Which city is hottest?"
  )

  print("🌤️ Weather Comparison Result:")
  print(response)
}
