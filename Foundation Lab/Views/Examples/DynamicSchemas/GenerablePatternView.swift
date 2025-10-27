//
//  GenerablePatternView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import SwiftUI
import FoundationModels

// MARK: - Generable Models

@Generable
struct Recipe {
    @Guide(description: "A creative and appetizing recipe name")
    let name: String

    @Guide(description: "Brief description of the dish")
    let description: String

    @Guide(description: "List of main ingredients", .count(3...5))
    let ingredients: [Ingredient]

    @Guide(description: "Difficulty level of the recipe")
    let difficulty: Difficulty

    @Guide(description: "Preparation time in minutes")
    let prepTime: Int

    @Guide(description: "Cooking time in minutes")
    let cookTime: Int

    @Guide(description: "Number of servings")
    let servings: Int

    @Generable
    struct Ingredient {
        let name: String
        let quantity: String
        let unit: MeasurementUnit
    }

    @Generable
    enum MeasurementUnit {
        case cups
        case tablespoons
        case teaspoons
        case ounces
        case pounds
        case grams
        case milliliters
        case pieces
    }

    @Generable
    enum Difficulty {
        case easy
        case medium
        case hard
        case expert
    }
}

@Generable
struct MovieReview {
    @Guide(description: "The movie title")
    let title: String

    @Guide(description: "Year the movie was released")
    let year: Int

    @Guide(description: "Movie genre")
    let genre: Genre

    @Guide(description: "Rating out of 5 stars", .range(1...5))
    let rating: Int

    @Guide(description: "A brief review of the movie")
    let review: String

    @Guide(description: "Whether you would recommend this movie")
    let wouldRecommend: Bool

    @Generable
    enum Genre {
        case action
        case comedy
        case drama
        case horror
        case sciFi
        case romance
        case documentary
        case animated
    }
}

// MARK: - View

struct GenerablePatternView: View {
    @State private var executor = ExampleExecutor()
    @State private var selectedExample = 0
    @State private var cuisineInput = "Italian"
    @State private var movieGenreInput = "sci-fi"

    private let examples = ["Recipe Generator", "Movie Review"]

    var body: some View {
        ExampleViewBase(
            title: "@Generable Pattern",
            description: "Use the @Generable macro with @Guide constraints for type-safe generation",
            defaultPrompt: currentPrompt,
            currentPrompt: .constant(currentPrompt),
            isRunning: executor.isRunning,
            errorMessage: executor.errorMessage,
            codeExample: exampleCode,
            onRun: { Task { await runExample() } },
            onReset: { selectedExample = 0 },
            content: {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                // Example selector
                Picker("Example", selection: $selectedExample) {
                    ForEach(0..<examples.count, id: \.self) { index in
                        Text(examples[index]).tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.bottom)

                // Input based on selection
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text(selectedExample == 0 ? "Cuisine Type" : "Movie Genre")
                        .font(.headline)

                    TextField(
                        selectedExample == 0 ? "Enter cuisine type" : "Enter movie genre",
                        text: selectedExample == 0 ? $cuisineInput : $movieGenreInput
                    )
                    .textFieldStyle(.roundedBorder)
                }

                // Info section
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("How @Generable Works")
                        .font(.headline)

                    Text(generableInfo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }

                HStack {
                    Button("Generate") {
                        Task {
                            await runExample()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(executor.isRunning || currentPrompt.isEmpty)

                    if executor.isRunning {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }

                // Results section
                if !executor.results.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Generated Data")
                            .font(.headline)

                        ScrollView {
                            Text(executor.results)
                                .font(.system(.caption, design: .monospaced))
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .frame(maxHeight: 300)
                    }
                }
            }
            .padding()
        }
        )
    }

    private var currentPrompt: String {
        selectedExample == 0 ? cuisineInput : movieGenreInput
    }

    private var generableInfo: String {
        if selectedExample == 0 {
            return """
            The @Generable macro automatically:
            • Creates schemas from Swift types
            • Enforces type safety
            • Applies @Guide constraints:
              - .count(3...5) for ingredients array
              - Descriptive hints for better generation
            • Handles nested types and enums
            """
        } else {
            return """
            Movie Review demonstrates:
            • Enum types for genres
            • Range constraints (.range(1...5) for ratings)
            • Boolean fields
            • Mixed data types (String, Int, Bool)
            • Automatic schema generation
            """
        }
    }

    private func runExample() async {
        await executor.execute {
            let session = LanguageModelSession()

            if selectedExample == 0 {
                // Recipe generation
                let prompt = """
                Create a delicious \(cuisineInput) recipe that would be perfect for a dinner party.
                Make it sound appetizing and include specific measurements for ingredients.
                """

                let response = try await session.respond(
                    to: Prompt(prompt),
                    generating: Recipe.self
                )

                let recipe = response.content

                return """
                🍳 Generated Recipe

                Name: \(recipe.name)
                Description: \(recipe.description)

                ⏱️ Time:
                • Prep: \(recipe.prepTime) minutes
                • Cook: \(recipe.cookTime) minutes
                • Total: \(recipe.prepTime + recipe.cookTime) minutes

                🍽️ Servings: \(recipe.servings)
                📊 Difficulty: \(String(describing: recipe.difficulty))

                📝 Ingredients:
                \(formatIngredients(recipe.ingredients))

                💡 Note: Generated using @Generable pattern with type safety and constraints
                """
            } else {
                // Movie review generation
                let prompt = """
                Write a review for a popular \(movieGenreInput) movie.
                Include your honest opinion and rating.
                """

                let response = try await session.respond(
                    to: Prompt(prompt),
                    generating: MovieReview.self
                )

                let review = response.content

                return """
                🎬 Movie Review

                Title: \(review.title) (\(review.year))
                Genre: \(String(describing: review.genre))
                Rating: \(String(repeating: "⭐", count: review.rating))/5

                📝 Review:
                \(review.review)

                👍 Would Recommend: \(review.wouldRecommend ? "Yes" : "No")

                💡 Note: Generated using @Generable with automatic enum handling and range constraints
                """
            }
        }
    }

    private func formatIngredients(_ ingredients: [Recipe.Ingredient]) -> String {
        ingredients.enumerated().map { index, ingredient in
            "  \(index + 1). \(ingredient.quantity) \(String(describing: ingredient.unit)) \(ingredient.name)"
        }.joined(separator: "\n")
    }

    private var exampleCode: String {
        """
        // Define your types with @Generable
        @Generable
        struct Recipe {
            @Guide(description: "A creative recipe name")
            let name: String

            @Guide(.count(3...5), description: "Main ingredients")
            let ingredients: [Ingredient]

            @Guide(description: "Difficulty level")
            let difficulty: Difficulty

            @Generable
            struct Ingredient {
                let name: String
                let quantity: String
                let unit: MeasurementUnit
            }

            @Generable
            enum Difficulty {
                case easy, medium, hard, expert
            }
        }

        // Use it directly with the session
        let response = try await session.respond(
            to: "Create an Italian recipe",
            generating: Recipe.self
        )

        let recipe = response.content
        // recipe is now a fully typed Recipe instance!

        // Benefits:
        // ✅ Type safety - no manual parsing
        // ✅ Automatic schema generation
        // ✅ Guide constraints enforced
        // ✅ Clean, readable code
        // ✅ Nested types supported
        """
    }
}

#Preview {
    NavigationStack {
        GenerablePatternView()
    }
}
