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

  print("📱 Product Review:")
  print("Product: \(review.content.productName)")
  print("Rating: \(review.content.rating)/5")
  print("\nReview: \(review.content.reviewText)")
  print("\nRecommendation: \(review.content.recommendation)")
  print("\nPros:")
  for pro in review.content.pros {
    print("• \(pro)")
  }
  print("\nCons:")
  for con in review.content.cons {
    print("• \(con)")
  }

  // Generate a summary with specific word count constraint
  let shortSummary = try await session.respond(
    to: "Summarize the above review in exactly 50 words or less."
  )

  print("\n📝 Summary (50 words or less):")
  print(shortSummary.content)

  // Example with different product
  print("\n--- Another Product Review ---")

  let laptopReview = try await session.respond(
    to: """
      Write a product review for a gaming laptop under $1500.
      Focus on performance, build quality, and value for money.
      """,
    generating: ProductReview.self
  )

  print("\n💻 Gaming Laptop Review:")
  print("Product: \(laptopReview.content.productName)")
  print("Rating: \(laptopReview.content.rating)/5")
  print("Review: \(laptopReview.content.reviewText)")
}
