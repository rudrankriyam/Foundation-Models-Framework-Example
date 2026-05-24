# Dynamic Schemas

Use this reference when the output schema is built at runtime: user-created forms, admin-configured extraction templates, imported schema-like definitions, invoice or receipt formats, and schema galleries.

Prefer `@Generable` for app-owned compile-time models. Use `DynamicGenerationSchema` only when the shape is not known until runtime.

## Object With Dependencies

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
```

## Generate Runtime Content

```swift
func extractReceipt(from text: String) async throws -> GeneratedContent {
    let schema = try makeReceiptSchema()
    let session = LanguageModelSession(
        instructions: "Extract only values present in the receipt text."
    )

    return try await session.respond(
        to: Prompt("Extract receipt data from this text:\n\(text)"),
        schema: schema,
        options: GenerationOptions(temperature: 0.1)
    ).content
}
```

## Read GeneratedContent

```swift
let output = try await extractReceipt(from: receiptText)
let merchant: String = try output.value(forProperty: "merchant")
let total: Double = try output.value(forProperty: "total")

print("\(merchant): \(total)")
```

## Enum-Like Choices

```swift
let priority = DynamicGenerationSchema(
    name: "Priority",
    description: "Task priority",
    anyOf: ["low", "medium", "high"]
)
```

## Optional Fields

```swift
DynamicGenerationSchema.Property(
    name: "notes",
    description: "Optional extra notes from the source",
    schema: DynamicGenerationSchema(type: String.self),
    isOptional: true
)
```

Optional means the property may be absent. Do not make fields optional just to avoid handling decoding errors.

## Retry After Schema Failure

```swift
func generateDynamicContentWithRetry(
    prompt: String,
    schema: GenerationSchema
) async throws -> GeneratedContent {
    let session = LanguageModelSession()

    do {
        return try await session.respond(to: Prompt(prompt), schema: schema).content
    } catch LanguageModelSession.GenerationError.decodingFailure {
        let retryPrompt = """
        \(prompt)

        Return only fields allowed by the schema. Do not include unknown fields.
        Use simple scalar values when possible.
        """

        return try await session.respond(
            to: Prompt(retryPrompt),
            schema: schema,
            options: GenerationOptions(temperature: 0.0)
        ).content
    }
}
```

## Checklist

- Name every schema and reference consistently.
- Pass dependencies whenever `referenceTo` is used.
- Keep schema construction separate from SwiftUI rendering.
- Add user-facing recovery for decoding failures.
- Use lower temperature for extraction and classification.
