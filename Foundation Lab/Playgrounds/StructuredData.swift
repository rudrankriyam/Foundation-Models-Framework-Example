import FoundationModels
import Playgrounds
import Foundation

#Playground {
  // Create a basic language model session
  let session = LanguageModelSession()


  // Generate structured data using @Generable types
  let bookInfo = try await session.respond(
    to: Prompt("Recommend a science fiction book with details."),
    generating: BookRecommendation.self
  )

    """
    📚 Book Recommendation:
    Title: \(bookInfo.content.title)
    Author: \(bookInfo.content.author)
    Genre: \(bookInfo.content.genre)

    Description: \(bookInfo.content.description)
    """)

  // Generate multiple book recommendations

  let genres = ["mystery", "fantasy", "biography"]

  for genre in genres {
    let recommendation = try await session.respond(
      to: Prompt("Recommend a \(genre) book with details."),
      generating: BookRecommendation.self
    )

  }
}
