import FoundationModels
import Playgrounds
import Foundation

#Playground {
  // Create a basic language model session
  let session = LanguageModelSession()

  print("Generating structured book recommendation...")

  // Generate structured data using @Generable types
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

  // Generate multiple book recommendations
  print("\n--- Multiple Recommendations ---")

  let genres = ["mystery", "fantasy", "biography"]

  for genre in genres {
    let recommendation = try await session.respond(
      to: Prompt("Recommend a \(genre) book with details."),
      generating: BookRecommendation.self
    )

    print("\n\(genre.capitalized) Book:")
    print("📖 \(recommendation.content.title) by \(recommendation.content.author)")
    print("Description: \(recommendation.content.description)")
  }
}
