# Structured Generation

Use this reference for compile-time structured output with `@Generable`, `@Guide`, enums, arrays, nested objects, and decoding retries.

Use `@Generable` when the app owns the output type. Use `references/dynamic-schemas.md` only when the schema must be assembled at runtime.

## Basic Model

```swift
import FoundationModels

@Generable
struct BookRecommendation: Sendable {
    @Guide(description: "The exact title of the recommended book")
    let title: String

    @Guide(description: "The author's full name")
    let author: String

    @Guide(description: "A short reason this book fits the user's request")
    let reason: String

    @Guide(description: "Difficulty from 1 for easy to 5 for demanding")
    let difficulty: Int
}

func recommendBook(for request: String) async throws -> BookRecommendation {
    let session = LanguageModelSession(
        instructions: "Recommend real books only. Do not invent authors."
    )

    let response = try await session.respond(
        to: Prompt(request),
        generating: BookRecommendation.self
    )

    return response.content
}
```

## Enum And Array Output

```swift
@Generable
enum ReviewSentiment: Sendable {
    case positive
    case mixed
    case negative
}

@Generable
struct ProductReviewSummary: Sendable {
    let productName: String
    let sentiment: ReviewSentiment

    @Guide(description: "Three concise strengths mentioned by the reviewer", .count(3))
    let pros: [String]

    @Guide(description: "One to three concrete weaknesses mentioned by the reviewer", .count(1...3))
    let cons: [String]
}

let summary = try await LanguageModelSession().respond(
    to: Prompt(reviewText),
    generating: ProductReviewSummary.self
).content
```

## Nested Output

```swift
@Generable
struct NutritionAnalysis: Sendable {
    let foodName: String
    let calories: Int
    let macros: Macros
    let notes: [String]

    @Generable
    struct Macros: Sendable {
        let proteinGrams: Double
        let carbohydrateGrams: Double
        let fatGrams: Double
    }
}
```

## Classification

```swift
@Generable
struct SupportTicketClassification: Sendable {
    let category: Category
    let urgency: Urgency

    @Guide(description: "One sentence explaining the classification")
    let rationale: String

    @Generable
    enum Category: Sendable {
        case billing
        case bug
        case featureRequest
        case account
        case other
    }

    @Generable
    enum Urgency: Sendable {
        case low
        case medium
        case high
    }
}
```

## Retry Strategy

Retry only after changing constraints. For structured output, lower temperature and make the prompt stricter.

```swift
func generateStructuredWithRetry<Output: Generable & Sendable>(
    _ type: Output.Type,
    prompt: String,
    instructions: String
) async throws -> Output {
    let session = LanguageModelSession(instructions: Instructions(instructions))

    do {
        return try await session.respond(to: Prompt(prompt), generating: type).content
    } catch LanguageModelSession.GenerationError.decodingFailure {
        let stricterPrompt = """
        \(prompt)

        Return only values that fit the requested Swift type.
        Avoid unknown, null, or extra fields.
        """

        return try await session.respond(
            to: Prompt(stricterPrompt),
            generating: type,
            options: GenerationOptions(temperature: 0.0)
        ).content
    }
}
```

## Checklist

- Prefer concrete property names over generic fields like `value`.
- Add guides for meaning, count, ranges, allowed style, or ambiguity.
- Keep generated types `Sendable` when crossing concurrency boundaries.
- Use lower temperature for extraction and classification.
- Handle `decodingFailure` with user-facing recovery.
