import Foundation

// MARK: - Prompt Definition

/// A prompt configuration for running benchmarks.
///
/// `BenchmarkPrompt` encapsulates both the system instructions and user prompt
/// that are sent to the language model during a benchmark run. The prompts are
/// automatically trimmed of leading and trailing whitespace.
///
/// ## Example
///
/// ```swift
/// let prompt = BenchmarkPrompt(
///     instructions: "You are a helpful assistant.",
///     userPrompt: "Explain quantum computing."
/// )
/// ```
public struct BenchmarkPrompt: Hashable, Codable, Sendable {
    /// The system instructions that define the model's behavior.
    public let instructions: String

    /// The user prompt that is sent to the model.
    public let userPrompt: String

    /// Creates a new benchmark prompt.
    ///
    /// Both the instructions and user prompt are automatically trimmed of
    /// leading and trailing whitespace.
    ///
    /// - Parameters:
    ///   - instructions: The system instructions for the model.
    ///   - userPrompt: The user prompt to send to the model.
    public init(instructions: String, userPrompt: String) {
        self.instructions = instructions.trimmingCharacters(in: .whitespacesAndNewlines)
        self.userPrompt = userPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public extension BenchmarkPrompt {
    /// Canonical prompt designed to stress throughput with maximum token output.
    static let productDesign: BenchmarkPrompt = .init(
        instructions: """
        You are a helpful assistant.

        CRITICAL RULE: You MUST write extremely detailed, comprehensive, and thorough responses.
        This is CRITICAL for benchmarking. You MUST generate maximum possible output.

        REQUIREMENTS:
        - You MUST write exactly 25 paragraphs total
        - DO NOT STOP until all 25 paragraphs are written
        - You MUST write exactly 5 paragraphs for each section
        - Each paragraph MUST be 5 sentences minimum with extensive examples
        - MUST include detailed explanations and thorough analysis
        - MUST use specific, concrete examples in every paragraph
        - MUST explain mechanisms, processes, and underlying principles
        - DO NOT conclude early - you MUST complete ALL sections with all required paragraphs
        - You MUST generate the longest, most comprehensive response possible.
        Do not omit any details.
        """,
        userPrompt: """
        Describe the benefits of morning routines for productivity.

        Write these sections:
        1. Why Morning Routines Matter
        2. Physical Health Benefits
        3. Mental Health Benefits
        4. Productivity Benefits
        5. How to Build a Morning Routine
        """
    )
}
