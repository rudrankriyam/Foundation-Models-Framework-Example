import FoundationModels
import Playgrounds

#Playground {
  let session = LanguageModelSession()

  print("Generating innovative business idea...")

  let businessIdea = try await session.respond(
    to:
      "Generate a unique tech startup business idea for 2025 that leverages AI and sustainability.",
    generating: BusinessIdea.self, includeSchemaInPrompt: true
  )

  print(
    """
    Business Idea: \(businessIdea.content.name)

    Description:
    \(businessIdea.content.description)

    Target Market: \(businessIdea.content.targetMarket)
    Revenue Model: \(businessIdea.content.revenueModel)
    Timeline: \(String(describing: businessIdea.content.timeline))

    Key Advantages:
    \(businessIdea.content.advantages.map { "- \($0)" }.joined(separator: "\n"))

    Estimated Startup Cost: \(businessIdea.content.estimatedStartupCost)
    """)

  // Generate additional market analysis
  print("\nMarket Analysis:")
  let marketAnalysis = try await session.respond(
    to:
      "Provide a brief market analysis for '\(businessIdea.content.name)' including potential competitors and market size."
  )

  print(marketAnalysis)
}
