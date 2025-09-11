import FoundationModels
import Playgrounds

#Playground {
  // Create a basic language model session
  let session = LanguageModelSession()

  // Generate a structured product review using @Guide annotations
  let review = try await session.respond(
    to: """
      Write a detailed product review for the iPhone 16 Pro. 
      The review must be balanced, include specific pros and cons, 
      and provide a rating between 1-5.
      """,
    generating: ProductReview.self
  )

  for pro in review.content.pros {
  }
  for con in review.content.cons {
  }

  // Generate a summary with specific word count constraint
  let shortSummary = try await session.respond(
    to: "Summarize the above review in exactly 50 words or less."
  )


  // Example with different product

  let laptopReview = try await session.respond(
    to: """
      Write a product review for a gaming laptop under $1500.
      Focus on performance, build quality, and value for money.
      """,
    generating: ProductReview.self
  )

}
