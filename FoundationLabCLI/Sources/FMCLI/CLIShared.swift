import ArgumentParser
import Foundation
import FoundationLabCore

enum CLIOutput {
    static func emit(payload: [String: Any], human: String, json: Bool) {
        if json {
            emitJSON(payload)
        } else {
            print(human)
        }
    }

    static func emitError(_ error: Error, json: Bool) {
        let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription

        if json {
            emitJSON([
                "status": "error",
                "message": message
            ])
        } else {
            fputs("Error: \(message)\n", stderr)
        }
    }

    private static func emitJSON(_ payload: [String: Any]) {
        guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(
                withJSONObject: payload,
                options: [.prettyPrinted, .sortedKeys]
              ),
              let text = String(data: data, encoding: .utf8) else {
            print("{\"status\":\"error\",\"message\":\"Failed to encode JSON output.\"}")
            return
        }

        print(text)
    }
}

func humanReadableBookOutput(
    for response: GenerateBookRecommendationResult,
    verbose: Bool
) -> String {
    var lines = [response.recommendation.plainTextSummary]

    if verbose {
        let provider = response.metadata.provider ?? "Unknown"
        let tokenCount = response.metadata.tokenCount.map(String.init) ?? "n/a"
        lines.append("Provider: \(provider)")
        lines.append("Token count: \(tokenCount)")
    }

    return lines.joined(separator: "\n\n")
}

func humanReadableNutritionOutput(
    for response: AnalyzeNutritionResult,
    verbose: Bool
) -> String {
    var lines = [
        response.analysis.foodName,
        "",
        "Calories: \(response.analysis.calories)",
        "Protein: \(response.analysis.proteinGrams)g",
        "Carbs: \(response.analysis.carbsGrams)g",
        "Fat: \(response.analysis.fatGrams)g",
        "",
        response.analysis.insights
    ]

    if verbose {
        let provider = response.metadata.provider ?? "Unknown"
        let tokenCount = response.metadata.tokenCount.map(String.init) ?? "n/a"
        lines.append("")
        lines.append("Provider: \(provider)")
        lines.append("Token count: \(tokenCount)")
    }

    return lines.joined(separator: "\n")
}

func humanReadableText(
    title: String,
    response: TextGenerationResult,
    verbose: Bool
) -> String {
    var lines = [title, "", response.content]

    if verbose {
        let provider = response.metadata.provider ?? "Unknown"
        let tokenCount = response.metadata.tokenCount.map(String.init) ?? "n/a"
        lines.append("")
        lines.append("Provider: \(provider)")
        lines.append("Token count: \(tokenCount)")
    }

    return lines.joined(separator: "\n")
}

func humanReadableConversationOutput(
    exchanges: [[String: String]],
    sessionCount: Int,
    tokenCount: Int,
    verbose: Bool,
    streamed: Bool
) -> String {
    var lines: [String] = []

    if !streamed {
        for exchange in exchanges {
            lines.append("User: \(exchange["message"] ?? "")")
            lines.append("Assistant: \(exchange["response"] ?? "")")
            lines.append("")
        }

        if !lines.isEmpty {
            lines.removeLast()
        }
    }

    if verbose {
        if !lines.isEmpty {
            lines.append("")
        }
        lines.append("Sessions: \(sessionCount)")
        lines.append("Token count: \(tokenCount)")
    }

    return lines.joined(separator: "\n")
}

func metadataPayload(_ metadata: CapabilityExecutionMetadata) -> [String: Any] {
    [
        "provider": metadata.provider ?? "",
        "modelIdentifier": metadata.modelIdentifier ?? "",
        "tokenCount": metadata.tokenCount as Any
    ]
}

enum CLIAvailabilityError: LocalizedError {
    case foundationModelsUnavailable(String)

    var errorDescription: String? {
        switch self {
        case .foundationModelsUnavailable(let message):
            return message
        }
    }
}

func validatedNonEmpty(_ value: String, optionName: String) throws -> String {
    let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedValue.isEmpty else {
        throw ValidationError("Please provide a non-empty \(optionName).")
    }
    return trimmedValue
}

func validatedNonEmptyValues(_ values: [String], optionName: String) throws -> [String] {
    let trimmedValues = values.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
    guard !trimmedValues.isEmpty else {
        throw ValidationError("Please provide at least one non-empty \(optionName).")
    }
    return trimmedValues
}

func cliContext() -> CapabilityInvocationContext {
    CapabilityInvocationContext(
        source: .cli,
        localeIdentifier: Locale.current.identifier
    )
}

func cliConversationConfiguration(systemPrompt: String?) -> FoundationLabConversationConfiguration {
    let trimmedSystemPrompt = systemPrompt?.trimmingCharacters(in: .whitespacesAndNewlines)
    let baseInstructions: String

    if let trimmedSystemPrompt, !trimmedSystemPrompt.isEmpty {
        baseInstructions = trimmedSystemPrompt
    } else {
        baseInstructions = """
        You are a helpful, friendly AI assistant. Engage in natural conversation and provide \
        thoughtful, detailed responses.
        """
    }

    return FoundationLabConversationConfiguration(
        baseInstructions: baseInstructions,
        summaryInstructions: """
        You are an expert at summarizing conversations. Create concise summaries that preserve \
        context needed to continue naturally.
        """,
        summaryPromptPreamble: """
        Please summarize the following conversation so the assistant can continue it naturally:
        """,
        conversationUserLabel: "User:",
        conversationAssistantLabel: "Assistant:",
        continuationNote: """
        Continue the conversation naturally, using this context when relevant.
        """,
        modelUseCase: .general,
        guardrails: .default,
        enableSlidingWindow: true,
        defaultMaxContextSize: 4_096
    )
}

func requireFoundationModelsAvailability() throws {
    let availability = CheckModelAvailabilityUseCase().execute()

    if availability.isAvailable {
        return
    }

    let reasonDescription: String
    switch availability.reason {
    case .deviceNotEligible:
        reasonDescription = "device not eligible"
    case .appleIntelligenceNotEnabled:
        reasonDescription = "Apple Intelligence not enabled"
    case .modelNotReady:
        reasonDescription = "model not ready"
    case .unknown, .none:
        reasonDescription = "unknown reason"
    }

    throw CLIAvailabilityError.foundationModelsUnavailable(
        "Apple Intelligence is unavailable for CLI execution: \(reasonDescription)"
    )
}
