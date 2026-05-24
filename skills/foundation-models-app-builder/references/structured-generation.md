# Structured Generation Recipes

Use these recipes for `@Generable`, `@Guide`, enums, arrays, nested objects, dynamic schemas, decoding failures, and retries.

## Compile-Time Model With `@Generable`

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
enum ReviewSentiment: String, Sendable {
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

## Dynamic Schema For Runtime Fields

```swift
import FoundationModels

func makeReceiptSchema() throws -> GenerationSchema {
    let lineItem = DynamicGenerationSchema(
        name: "LineItem",
        description: "One purchased item",
        properties: [
            DynamicGenerationSchema.Property(
                name: "name",
                description: "Item name",
                schema: DynamicGenerationSchema(type: String.self)
            ),
            DynamicGenerationSchema.Property(
                name: "price",
                description: "Item price in the receipt currency",
                schema: DynamicGenerationSchema(type: Double.self)
            )
        ]
    )

    let receipt = DynamicGenerationSchema(
        name: "Receipt",
        description: "Receipt extracted from plain text",
        properties: [
            DynamicGenerationSchema.Property(
                name: "merchant",
                schema: DynamicGenerationSchema(type: String.self)
            ),
            DynamicGenerationSchema.Property(
                name: "items",
                schema: DynamicGenerationSchema(
                    arrayOf: DynamicGenerationSchema(referenceTo: "LineItem"),
                    minimumElements: 1
                )
            ),
            DynamicGenerationSchema.Property(
                name: "total",
                schema: DynamicGenerationSchema(type: Double.self)
            )
        ]
    )

    return try GenerationSchema(root: receipt, dependencies: [lineItem])
}

func extractReceipt(from text: String) async throws -> GeneratedContent {
    let schema = try makeReceiptSchema()
    let session = LanguageModelSession()

    return try await session.respond(
        to: Prompt("Extract the receipt data from this text:\n\(text)"),
        schema: schema,
        options: GenerationOptions(temperature: 0.1)
    ).content
}
```

## Reading Dynamic Output

```swift
let output = try await extractReceipt(from: receiptText)
let merchant: String = try output.value(forProperty: "merchant")
let total: Double = try output.value(forProperty: "total")

print("\(merchant): \(total)")
```

## Retry Strategy For Decoding Failure

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

        Return only values that fit the requested schema. Avoid unknown, null, or extra fields.
        """

        return try await session.respond(
            to: Prompt(stricterPrompt),
            generating: type,
            options: GenerationOptions(temperature: 0.0)
        ).content
    }
}
```

## Choosing Static vs Dynamic

- Use `@Generable` for app-owned models such as recommendations, summaries, classifications, health summaries, reminders, or intent results.
- Use dynamic schemas for user-built forms, imported JSON schema-like definitions, runtime invoice/receipt formats, and admin-configured extraction templates.
- Do not use dynamic schemas just to avoid defining Swift types. Static types are clearer, safer, and easier to test.
