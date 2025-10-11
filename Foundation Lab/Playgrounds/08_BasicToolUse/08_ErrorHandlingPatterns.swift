//
//  08_ErrorHandlingPatterns.swift
//  Exploring Foundation Models
//
//  Created by Rudrank Riyam on 9/24/25.
//

import Foundation
import FoundationModels
import Playgrounds

// Example tool that demonstrates comprehensive error handling
struct RobustTool: Tool {
    let name = "robustExample"
    let description = "Demonstrates comprehensive error handling patterns for tool development"

    @Generable
    struct Arguments {
        @Guide(description: "Input value to process")
        var input: String

        @Guide(description: "Processing mode: 'normal', 'simulate_error', or 'invalid_input'")
        var mode: String?
    }

    @Generable
    struct ToolResult {
        let input: String
        let output: String
        let processingTime: Double
        let status: String
    }

    enum ToolError: Error, LocalizedError {
        case invalidInput(String)
        case processingFailed(String)
        case networkUnavailable
        case rateLimitExceeded

        var errorDescription: String? {
            switch self {
            case .invalidInput(let details):
                return "Invalid input provided: \(details)"
            case .processingFailed(let reason):
                return "Processing failed: \(reason)"
            case .networkUnavailable:
                return "Network connection is unavailable"
            case .rateLimitExceeded:
                return "Rate limit exceeded. Please try again later."
            }
        }
    }

    func call(arguments: Arguments) async throws -> ToolResult {
        let startTime = Date()
        let mode = arguments.mode?.lowercased() ?? "normal"

        // Input validation
        guard !arguments.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return createErrorOutput(
                input: arguments.input,
                error: ToolError.invalidInput("Input cannot be empty"),
                processingTime: Date().timeIntervalSince(startTime)
            )
        }

        // Simulate different error scenarios for demonstration
        switch mode {
        case "simulate_error":
            return createErrorOutput(
                input: arguments.input,
                error: ToolError.processingFailed("Simulated processing error"),
                processingTime: Date().timeIntervalSince(startTime)
            )

        case "invalid_input":
            return createErrorOutput(
                input: arguments.input,
                error: ToolError.invalidInput("Input format not recognized"),
                processingTime: Date().timeIntervalSince(startTime)
            )

        case "network_error":
            return createErrorOutput(
                input: arguments.input,
                error: ToolError.networkUnavailable,
                processingTime: Date().timeIntervalSince(startTime)
            )

        default:
            // Normal processing
            let processedOutput = "Successfully processed: \(arguments.input)"
            let processingTime = Date().timeIntervalSince(startTime)

            return ToolResult(
                input: arguments.input,
                output: processedOutput,
                processingTime: processingTime,
                status: "success"
            )
        }
    }

    private func createErrorOutput(input: String, error: Error, processingTime: TimeInterval) -> ToolResult {
        ToolResult(
            input: input,
            output: "Error: \(error.localizedDescription). \(getSuggestionForError(error))",
            processingTime: processingTime,
            status: "error"
        )
    }

    private func getSuggestionForError(_ error: Error) -> String {
        if let toolError = error as? ToolError {
            switch toolError {
            case .invalidInput:
                return "Please provide a valid, non-empty input string."
            case .processingFailed:
                return "Try again with different input or check your request format."
            case .networkUnavailable:
                return "Check your internet connection and try again."
            case .rateLimitExceeded:
                return "Wait a few minutes before making another request."
            }
        }
        return "Please try again or contact support if the problem persists."
    }
}

#Playground {
    // Test various error scenarios
    let robustTool = RobustTool()

    debugPrint("=== Testing Normal Operation ===")
    let normalArgs = RobustTool.Arguments(input: "Hello, World!", mode: "normal")
    let normalResult = try await robustTool.call(arguments: normalArgs)
    debugPrint("Normal result: \(normalResult)")

    debugPrint("\n=== Testing Empty Input ===")
    let emptyArgs = RobustTool.Arguments(input: "", mode: "normal")
    let emptyResult = try await robustTool.call(arguments: emptyArgs)
    debugPrint("Empty input result: \(emptyResult)")

    debugPrint("\n=== Testing Simulated Error ===")
    let errorArgs = RobustTool.Arguments(input: "Test input", mode: "simulate_error")
    let errorResult = try await robustTool.call(arguments: errorArgs)
    debugPrint("Error simulation result: \(errorResult)")

    debugPrint("\n=== Testing Invalid Input Error ===")
    let invalidArgs = RobustTool.Arguments(input: "Test input", mode: "invalid_input")
    let invalidResult = try await robustTool.call(arguments: invalidArgs)
    debugPrint("Invalid input result: \(invalidResult)")
}

#Playground {
    // Session-level error handling
    let errorHandlingInstructions = """
    You are an assistant that gracefully handles tool errors. When a tool returns an error:
    1. Acknowledge the error occurred
    2. Explain what went wrong in user-friendly terms
    3. Provide suggestions for how to resolve the issue
    4. Offer alternative approaches if possible

    Always be helpful and never just report raw error messages.
    """

    let session = LanguageModelSession(
        tools: [RobustTool()],
        instructions: errorHandlingInstructions
    )

    // Test how the session handles tool errors
    let testQueries = [
        "Process an empty string",
        "Process 'Hello World' but simulate an error",
        "Process 'Valid Input' normally"
    ]

    for query in testQueries {
        debugPrint("\n--- Testing: \(query) ---")
        let response = try await session.respond(to: query)
        debugPrint("Session response: \(response.content)")
    }
}
