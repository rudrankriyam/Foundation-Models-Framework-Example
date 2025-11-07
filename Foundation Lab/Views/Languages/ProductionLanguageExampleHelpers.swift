//
//  ProductionLanguageExampleHelpers.swift
//  Foundation Lab
//
//  Created by Rudrank Riyam on 10/27/25.
//

import Foundation
import FoundationModels
import SwiftUI

extension ProductionLanguageExampleView {
    struct PromptConfig {
        let selectedLanguage: String
        let foodDescription: String
    }

    func createNutritionInstructions(config: PromptConfig) -> String {
        """
        You are a nutrition expert specializing in food analysis and macro tracking.

        IMPORTANT: Respond in \(config.selectedLanguage). All your responses must be in the user's language: \(config.selectedLanguage)

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
        Language: \(config.selectedLanguage)
        """
    }

    func createNutritionPrompt(config: PromptConfig) -> String {
        """
        RESPOND IN \(config.selectedLanguage). Parse this food description into nutritional data: "\(config.foodDescription)"

        Examples of good parsing:
        "I had 2 scrambled eggs with toast" → Consider: 2 large eggs (~140 cal), 1 slice toast (~80 cal), cooking butter (~30 cal)
        "protein shake after workout" → Consider: 1 scoop protein powder (~120 cal) + milk/water
        "pizza slice for lunch" → Consider: 1 slice medium pizza (~280 cal)

        Be realistic about portions people actually eat.
        Account for cooking methods and common additions.

        Language: \(config.selectedLanguage)
        """
    }

    func createInsightsPrompt(config: PromptConfig, response: LanguageModelSession.Response<NutritionParseResult>) -> String {
        """
        RESPOND IN \(config.selectedLanguage). Provide brief, encouraging nutritional insights about this meal:
        \(response.content.foodName) with \(response.content.calories) calories,
        \(response.content.proteinGrams)g protein, \(response.content.carbsGrams)g carbs,
        \(response.content.fatGrams)g fat.

        Be supportive and focus on the positive aspects. Keep it brief (2-3 sentences).
        Language: \(config.selectedLanguage)
        """
    }

    func createNutritionResult(_ response: LanguageModelSession.Response<NutritionParseResult>,
                               _ insightsResponse: LanguageModelSession.Response<String>) -> NutritionResult {
        NutritionResult(
            foodName: response.content.foodName,
            calories: response.content.calories,
            proteinGrams: response.content.proteinGrams,
            carbsGrams: response.content.carbsGrams,
            fatGrams: response.content.fatGrams,
            insights: insightsResponse.content
        )
    }

    @ViewBuilder
    func implementationSectionView() -> some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("Implementation Details")
                .font(.headline)
                .padding(.horizontal)

            CodeViewer(
                code: """
struct NutritionAnalysisService {
    func analyze(_ description: String, language: String) async throws -> NutritionResult {
        let session = LanguageModelSession(instructions: \"\"\"
            You are a nutrition expert specializing in food analysis.

            IMPORTANT: Respond in \\(language). All responses must be in: \\(language)

            When parsing food descriptions:
            - Estimate realistic portions for typical adults
            - Consider cooking methods and additions
            - Be practical with portion sizes
            - Round to reasonable numbers

            Tone: Supportive, knowledgeable, practical, encouraging.
            Language: \\(language)
            \"\"\")

        return try await session.respond(
            to: description,
            generating: NutritionResult.self
        ).content
    }
}
"""
            )
        }
        .padding(.horizontal)
    }
}
