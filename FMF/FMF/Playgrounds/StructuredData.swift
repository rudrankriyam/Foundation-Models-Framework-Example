import FoundationModels
import Playgrounds

#Playground {
  let session = LanguageModelSession()

  print("Generating structured book recommendation...")

  let bookInfo = try await session.respond(
    to: Prompt("Recommend a science fiction book with details."),
    generating: BookRecommendation.self
  )

  print(
    """
    📚 Book Recommendation:
    Title: \(bookInfo.content.title)
    Author: \(bookInfo.content.author)
    Genre: \(bookInfo.content.genre)

    Description: \(bookInfo.content.description)
    """)
}
