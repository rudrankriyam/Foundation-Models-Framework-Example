import FoundationModels
import Playgrounds

#Playground {
  let session = LanguageModelSession()

  let review = try await session.respond(
    to: """
      Write a detailed product review for the iPhone 16 Pro. 
      The review must be balanced, include specific pros and cons, 
      and provide a rating between 1-5.
      """,
    generating: ProductReview.self
  )

  let shortSummary = try await session.respond(
    to: "Summarize the above review in exactly 50 words or less."
  )
}
