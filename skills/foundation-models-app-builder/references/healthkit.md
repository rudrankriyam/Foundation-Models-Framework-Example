# HealthKit

Use this reference for HealthKit-backed Foundation Models features such as summaries, trends, coaching, nutrition analysis, and wellness check-ins.

Health features must be conservative. Summarize, explain, and encourage. Do not diagnose, prescribe, or claim medical certainty.

## Safe Instructions

```swift
let healthInstructions = Instructions("""
You are a wellness assistant.
Summarize trends and encourage healthy habits.
Do not diagnose, prescribe, or claim medical certainty.
Tell the user to consult a qualified professional for medical concerns.
""")
```

## Metric Summary Model

```swift
import FoundationModels

@Generable
struct HealthSummary: Sendable {
    let title: String
    let overview: String

    @Guide(description: "Two to four notable metric trends", .count(2...4))
    let trends: [String]

    @Guide(description: "Practical wellness suggestions, not medical advice", .count(1...3))
    let suggestions: [String]

    let safetyNote: String
}
```

## Generate Health Summary

```swift
func generateHealthSummary(metricText: String) async throws -> HealthSummary {
    let session = LanguageModelSession(instructions: healthInstructions)
    let prompt = """
    Summarize these HealthKit metrics.
    Include the date range and avoid diagnosis.

    Metrics:
    \(metricText)
    """

    return try await session.respond(
        to: Prompt(prompt),
        generating: HealthSummary.self,
        options: GenerationOptions(temperature: 0.2)
    ).content
}
```

## HealthKit Boundary Rules

- Request HealthKit authorization before model generation.
- Pass only the metrics needed for the feature.
- Include date ranges and units in prompt context.
- Handle denied authorization and empty data as normal UI states.
- Keep model output framed as educational or motivational.
- Do not say the model detected a disease, condition, or diagnosis.

## Review Wording

Prefer:

- "Your step count was lower than usual this week."
- "Consider reviewing this with a clinician if it concerns you."
- "This summary is based on the data available on this device."

Avoid:

- "You have..."
- "This indicates..."
- "You should take..."
- "The model diagnosed..."
