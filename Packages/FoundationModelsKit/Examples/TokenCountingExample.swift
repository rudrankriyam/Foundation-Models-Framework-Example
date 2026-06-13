//
//  TokenCountingExample.swift
//  FoundationModelsTools
//
//  Example demonstrating token counting and context window management
//

import Foundation
import FoundationModels
import FoundationModelsTools

// MARK: - Basic Token Counting

func basicTokenCountingExample() {
  let transcript = Transcript([
    .instructions("You are a helpful assistant"),
    .prompt("What's the weather like?"),
    .response("The weather is sunny and 72°F"),
  ])

  // Get token estimate
  let tokens = transcript.estimatedTokenCount
  print("Estimated tokens: \(tokens)")

  // Get safe estimate with buffer
  let safeTokens = transcript.safeEstimatedTokenCount
  print("Safe estimate: \(safeTokens)")
}

// MARK: - Context Window Management

func contextWindowExample() {
  let transcript = Transcript([
    .instructions("You are a helpful assistant"),
    .prompt("What's the weather like?"),
    .response("The weather is sunny and 72°F"),
    .prompt("What about tomorrow?"),
    .response("Tomorrow will be cloudy with a high of 68°F"),
  ])

  // Check if approaching limit (default: 70% of 4096 tokens)
  if transcript.isApproachingLimit() {
    print("Warning: Approaching context limit")
  }

  // Custom threshold and max tokens
  if transcript.isApproachingLimit(threshold: 0.8, maxTokens: 8192) {
    print("Using 80% threshold with 8K token limit")
  } else {
    print("Within safe limits")
  }
}

// MARK: - Sliding Window Implementation

func slidingWindowExample() {
  // Simulate a long conversation
  var entries: [Transcript.Entry] = [
    .instructions("You are a helpful assistant")
  ]

  // Add many conversation turns
  for i in 1...20 {
    entries.append(.prompt("Question \(i)"))
    entries.append(.response("Answer \(i)"))
  }

  let transcript = Transcript(entries)
  print("Original transcript tokens: \(transcript.estimatedTokenCount)")

  // Trim to budget
  let maxTokens = 2000
  let trimmedEntries = transcript.entriesWithinTokenBudget(maxTokens)
  let newTranscript = Transcript(trimmedEntries)

  print("Trimmed transcript tokens: \(newTranscript.estimatedTokenCount)")
  print("Number of entries kept: \(trimmedEntries.count) of \(entries.count)")
}

// MARK: - Standalone Token Estimation

func standaloneEstimationExample() {
  // Estimate tokens from text
  let text = "Hello, world! How are you doing today?"
  let textTokens = estimateTokens(from: text)
  print("Text '\(text)' uses approximately \(textTokens) tokens")

  // For structured content, you would use:
  // let content = GeneratedContent(...)
  // let contentTokens = estimateTokens(from: content)
}

// MARK: - Chat Manager with Token Management

class ChatManager {
  private var transcript = Transcript()
  private let maxTokens = 4096
  private let threshold = 0.7
  private let historyTokenBudgetPercentage = 0.6
  private let session: LanguageModelSession

  init(systemInstructions: String) {
    transcript = Transcript([.instructions(systemInstructions)])
    session = LanguageModelSession(model: .instant)
  }

  func addMessage(_ message: String) async throws -> String {
    // Add user message
    transcript.append(.prompt(message))

    print("Tokens before trim: \(transcript.estimatedTokenCount)")

    // Check if we're approaching the limit
    if transcript.isApproachingLimit(threshold: threshold, maxTokens: maxTokens) {
      print("⚠️ Approaching token limit, trimming context...")

      // Trim to fit budget (leaving room for response)
      let budget = Int(Double(maxTokens) * historyTokenBudgetPercentage)
      let trimmedEntries = transcript.entriesWithinTokenBudget(budget)
      transcript = Transcript(trimmedEntries)

      print("Trimmed transcript to \(transcript.estimatedTokenCount) tokens")
    }

    // Generate response with managed context
    let response = try await session.generate(from: transcript)
    transcript.append(.response(response))

    return response.text
  }

  func getCurrentTokenCount() -> Int {
    return transcript.safeEstimatedTokenCount
  }
}

// MARK: - Usage Example

@main
struct TokenCountingExampleApp {
  static func main() async {
    print("=== Token Counting Examples ===\n")

    print("1. Basic Token Counting:")
    basicTokenCountingExample()

    print("\n2. Context Window Management:")
    contextWindowExample()

    print("\n3. Sliding Window:")
    slidingWindowExample()

    print("\n4. Standalone Estimation:")
    standaloneEstimationExample()

    print("\n5. Chat Manager with Token Management:")
    let chatManager = ChatManager(systemInstructions: "You are a helpful assistant")

    do {
      let response1 = try await chatManager.addMessage("Hello!")
      print("Response: \(response1)")
      print("Current tokens: \(chatManager.getCurrentTokenCount())")

      // Simulate many messages
      for i in 1...10 {
        _ = try await chatManager.addMessage("Tell me about topic \(i)")
        print("After message \(i): \(chatManager.getCurrentTokenCount()) tokens")
      }
    } catch {
      print("Error: \(error)")
    }
  }
}
