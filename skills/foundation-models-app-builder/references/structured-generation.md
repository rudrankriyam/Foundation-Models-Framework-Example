# Structured Generation

Use this reference for `@Generable`, `@Guide`, `DynamicGenerationSchema`, and output parsing work.

## Choose The Right Output Shape

- Use `@Generable` when the app knows the output type at compile time.
- Use `DynamicGenerationSchema` when the schema is built at runtime, such as form builders, imported schemas, user-defined fields, invoice extraction, or schema galleries.
- Use plain text only when the output is meant for direct display and not app logic.

## `@Generable` Pattern

Place reusable generated models in `FoundationLabCore/Sources/FoundationLabCore/Models/` when multiple adapters need them. Keep example-only models near their example view when they exist only for teaching.

Inspect:

- `BookRecommendation.swift`
- `ProductReview.swift`
- `StoryOutline.swift`
- `NutritionAnalysis.swift`
- `FoundationModelsStructuredGenerator.swift`

Prefer guides that constrain meaning, counts, ranges, or allowed values. Avoid vague descriptions that only restate the property name.

## Dynamic Schema Pattern

Inspect the dynamic schema examples before writing new schema code:

- `BasicDynamicSchemaView.swift`
- `ArrayDynamicSchemaHelpers.swift`
- `EnumDynamicSchemaHelpers.swift`
- `NestedDynamicSchemaHelpers.swift`
- `ReferencedSchemaHelpers.swift`
- `UnionTypesSchemaHelpers.swift`
- `InvoiceProcessingSchemaHelpers.swift`
- `SchemaErrorHandlingHelpers.swift`

When building dynamic schemas:

- Name schemas and references consistently.
- Pass dependencies explicitly when references are used.
- Decide optionality intentionally with `isOptional`.
- Add error handling examples for missing required fields, invalid schema choices, and decoding failures.
- Keep schema construction separate from SwiftUI rendering when possible.

## Failure Handling

Handle structured-generation failures as product behavior, not just thrown errors:

- show a useful user-facing message
- preserve the original prompt/input when retrying
- allow the user to adjust constraints
- log enough context to diagnose schema mismatch without exposing private user data

## Review Checklist

- Does the app need structured output, or would text be enough?
- Is the schema compile-time or runtime?
- Are guides useful and specific?
- Are optional fields intentional?
- Are generated models `Sendable`-safe where they cross concurrency boundaries?
- Is there a fallback for model unavailability or decoding failure?
