import FoundationModels
import Playgrounds

#Playground {
  // Create a basic language model session
  let session = LanguageModelSession()


  // Generate structured story outline
  let storyOutline = try await session.respond(
    to:
      "Create an outline for a mystery story set in a small coastal town with supernatural elements.",
    generating: StoryOutline.self
  )

  debugPrint("""
    Story Outline: \(storyOutline.content.title)

    Genre: \(storyOutline.content.genre)
    Setting: \(storyOutline.content.setting)
    Protagonist: \(storyOutline.content.protagonist)

    Central Conflict:
    \(storyOutline.content.conflict)

    Themes:
    \(storyOutline.content.themes.map { "- \($0)" }.joined(separator: "\n"))
    """)

  // Generate opening scene based on the outline

  let openingScene = try await session.respond(
    to:
      "Write the opening paragraph for the story '\(storyOutline.content.title)' featuring \(storyOutline.content.protagonist) in \(storyOutline.content.setting)."
  )

  debugPrint("Opening Scene: \(openingScene.content)")


  // Generate character development

  let characterDevelopment = try await session.respond(
    to:
      "Describe the backstory and motivation of \(storyOutline.content.protagonist) in 2-3 sentences."
  )

  debugPrint("Character Development: \(characterDevelopment.content)")


  // Create another story outline with different genre

  let sciFiOutline = try await session.respond(
    to: "Create an outline for a sci-fi adventure story about space exploration and alien contact.",
    generating: StoryOutline.self
  )

  debugPrint("""
    Sci-Fi Story: \(sciFiOutline.content.title)

    Genre: \(sciFiOutline.content.genre)
    Setting: \(sciFiOutline.content.setting)
    Protagonist: \(sciFiOutline.content.protagonist)

    Conflict: \(sciFiOutline.content.conflict)
    """)
}
