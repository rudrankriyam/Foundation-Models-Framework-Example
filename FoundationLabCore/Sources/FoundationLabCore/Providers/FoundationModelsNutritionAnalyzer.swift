import Foundation
import FoundationModels

public struct FoundationModelsNutritionAnalyzer: NutritionAnalyzing {
    public init() {}

    public func analyzeNutrition(
        for request: AnalyzeNutritionRequest
    ) async throws -> AnalyzeNutritionResult {
        let session = LanguageModelSession(
            instructions: Instructions(
                nutritionInstructions(responseLanguage: request.responseLanguage)
            )
        )

        let parseResponse = try await session.respond(
            to: Prompt(
                nutritionPrompt(
                    foodDescription: request.foodDescription,
                    responseLanguage: request.responseLanguage
                )
            ),
            generating: NutritionParsePayload.self
        )

        let insightsResponse = try await session.respond(
            to: Prompt(
                nutritionInsightsPrompt(
                    parsedNutrition: parseResponse.content,
                    responseLanguage: request.responseLanguage
                )
            )
        )

        let tokenCount = await session.transcript.foundationLabTokenCount()

        return AnalyzeNutritionResult(
            analysis: NutritionAnalysis(
                foodName: parseResponse.content.foodName,
                calories: parseResponse.content.calories,
                proteinGrams: parseResponse.content.proteinGrams,
                carbsGrams: parseResponse.content.carbsGrams,
                fatGrams: parseResponse.content.fatGrams,
                insights: insightsResponse.content
            ),
            metadata: CapabilityExecutionMetadata(
                provider: "Foundation Models",
                tokenCount: tokenCount
            )
        )
    }
}

private func nutritionInstructions(responseLanguage: String) -> String {
    """
    You are a nutrition expert specializing in food analysis and macro tracking.

    IMPORTANT: Respond in \(responseLanguage). All your responses must be in the user's language: \(responseLanguage)

    When parsing food descriptions:
    - Estimate realistic portions for typical adults
    - Consider cooking methods (grilled vs fried affects calories)
    - Account for common additions (butter, oil, condiments)
    - Be practical with portion sizes people actually eat
    - Round to reasonable numbers (don't say 247.3 calories, say ~250)

    For nutritional insights:
    - Focus on energy for fitness and performance
    - Be encouraging and supportive like a fitness coach
    - Highlight good nutritional choices
    - Suggest balance when needed
    - Keep responses brief and actionable

    Tone: Supportive, knowledgeable, practical, encouraging.
    Language: \(responseLanguage)
    """
}

private func nutritionPrompt(
    foodDescription: String,
    responseLanguage: String
) -> String {
    """
    RESPOND IN \(responseLanguage). Parse this food description into nutritional data: "\(foodDescription)"

    Examples of good parsing:
    "I had 2 scrambled eggs with toast" -> Consider: 2 large eggs (~140 cal), 1 slice toast (~80 cal), cooking butter (~30 cal)
    "protein shake after workout" -> Consider: 1 scoop protein powder (~120 cal) + milk/water
    "pizza slice for lunch" -> Consider: 1 slice medium pizza (~280 cal)

    Be realistic about portions people actually eat.
    Account for cooking methods and common additions.

    Language: \(responseLanguage)
    """
}

private func nutritionInsightsPrompt(
    parsedNutrition: NutritionParsePayload,
    responseLanguage: String
) -> String {
    """
    RESPOND IN \(responseLanguage). Provide brief, encouraging nutritional insights about this meal:
    \(parsedNutrition.foodName) with \(parsedNutrition.calories) calories,
    \(parsedNutrition.proteinGrams)g protein, \(parsedNutrition.carbsGrams)g carbs,
    \(parsedNutrition.fatGrams)g fat.

    Be supportive and focus on the positive aspects. Keep it brief (2-3 sentences).
    Language: \(responseLanguage)
    """
}

@Generable
private struct NutritionParsePayload {
    @Guide(description: "The name or description of the food item")
    let foodName: String

    @Guide(description: "Estimated calories as a whole number")
    let calories: Int

    @Guide(description: "Protein content in grams as a whole number")
    let proteinGrams: Int

    @Guide(description: "Carbohydrate content in grams as a whole number")
    let carbsGrams: Int

    @Guide(description: "Fat content in grams as a whole number")
    let fatGrams: Int
}
