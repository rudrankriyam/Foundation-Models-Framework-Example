import FoundationModels
import Playgrounds

#Playground {
  let session = LanguageModelSession()

  let storyOutline = try await session.respond(
    to: "Create an outline for a mystery story set in a small coastal town with supernatural elements.",
    generating: StoryOutline.self
  )

  let openingScene = try await session.respond(
    to:
      "Write the opening paragraph for the story '\(storyOutline.content.title)' featuring \(storyOutline.content.protagonist) in \(storyOutline.content.setting)."
  )
}
