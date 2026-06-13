//
//  Transcript+HistoryTransforms.swift
//  FoundationModelsTools
//
//  Transcript history transforms for Foundation Models conversations.
//

import FoundationModels

extension Collection where Element == Transcript.Entry {
  /// Returns the most recent transcript entries.
  ///
  /// This is an entry-count rolling window. Unlike ``entriesWithinTokenBudget(_:)``,
  /// it does not preserve instructions specially or estimate token usage. It
  /// mirrors the entry-window behavior used by Foundation Models history
  /// profile modifiers.
  ///
  /// - Parameter entries: The maximum number of recent entries to keep.
  /// - Returns: The latest entries in chronological order.
  public func rollingWindow(entries: Int) -> [Transcript.Entry] {
    guard entries > 0 else { return [] }
    return Array(suffix(entries))
  }

  /// Returns transcript entries with older completed tool-call exchanges removed.
  ///
  /// Tool calls and tool outputs from turns before the latest user prompt are
  /// removed. Tool activity after the latest prompt is preserved as the active
  /// exchange.
  ///
  /// This keeps old tool chatter from growing context while retaining the latest
  /// active tool exchange.
  public func droppingCompletedToolCalls() -> [Transcript.Entry] {
    let entries = Array(self)

    guard !entries.isEmpty else {
      return []
    }

    guard let latestPromptIndex = entries.lastIndex(where: { entry in
      if case .prompt = entry { return true }
      return false
    }) else {
      return entries
    }

    return entries.enumerated().compactMap { index, entry in
      guard index < latestPromptIndex else {
        return entry
      }

      if case .toolCalls = entry { return nil }
      if case .toolOutput = entry { return nil }
      return entry
    }
  }

  /// Returns transcript entries with earlier history summarized into the latest prompt.
  ///
  /// The helper summarizes only when the collection has more entries than
  /// `entryThreshold` and the latest entry is a prompt. Otherwise, the original
  /// entries are returned unchanged.
  ///
  /// When summarization runs, the returned history preserves instruction
  /// entries, then adds a single prompt. The prompt starts with a text segment
  /// containing the generated summary and optional postamble, followed by the
  /// latest prompt's original segments, options, and response format.
  ///
  /// - Parameters:
  ///   - entryThreshold: Summarize only when the entry count is greater than this value.
  ///   - summaryPostamble: Text appended after the summary. Pass an empty string
  ///     to omit the postamble. Pass `nil` to use the default postamble.
  ///   - summarize: A closure that receives a summarization prompt and returns
  ///     the summary text.
  /// - Returns: The summarized entries, or the original entries when the
  ///   threshold is not exceeded or the latest entry is not a prompt.
  public func summarizingHistory(
    entryThreshold: Int,
    summaryPostamble: String? = nil,
    summarize: (String) async throws -> String
  ) async rethrows -> [Transcript.Entry] {
    let entries = Array(self)

    guard entries.count > entryThreshold else {
      return entries
    }

    guard case .prompt(let prompt) = entries.last else {
      return entries
    }

    let summary = try await summarize(transcriptSummaryPrompt(for: entries.chatLog()))
    let postamble = summaryPostamble ?? defaultTranscriptSummaryPostamble
    var summaryContent = """
      Summary of the conversation so far:
      \(summary)
      """

    if !postamble.isEmpty {
      summaryContent += "\n\n\(postamble)"
    }

    summaryContent += "\n\n"

    let summarySegment = Transcript.TextSegment(content: summaryContent)
    let summarizedPrompt = Transcript.Prompt(
      segments: [.text(summarySegment)] + prompt.segments,
      options: prompt.options,
      responseFormat: prompt.responseFormat
    )

    let instructions = entries.filter { entry in
      if case .instructions = entry { return true }
      return false
    }

    return instructions + [.prompt(summarizedPrompt)]
  }
}

private let defaultTranscriptSummaryPostamble = """
  Do not begin with phrases like "Based on the context", "Based on the facts", \
  "Based on the summary", or any reference to a summary or the facts provided. \
  Treat the summary and facts above as things you naturally remember.
  """

private func transcriptSummaryPrompt(for chatLog: String) -> String {
  "Summarize this conversation:\n\n\(chatLog)"
}

private extension Sequence where Element == Transcript.Entry {
  func chatLog(separator: String = "\n") -> String {
    compactMap(\.chatText).joined(separator: separator)
  }
}

private extension Transcript.Entry {
  var chatText: String? {
    if case .prompt(let prompt) = self {
      return "User: \(prompt.segments.textContent)"
    }

    if case .response(let response) = self {
      return "Assistant: \(response.segments.textContent)"
    }

    if case .toolCalls(let calls) = self {
      let renderedCalls = calls
        .map { "\($0.toolName)(\($0.arguments))" }
        .joined(separator: ", ")
      return "Tool call: \(renderedCalls)"
    }

    if case .toolOutput(let output) = self {
      return "Tool output (\(output.toolName)): \(output.segments.textContent)"
    }

    return nil
  }
}

private extension Sequence where Element == Transcript.Segment {
  var textContent: String {
    compactMap { segment in
      if case .text(let textSegment) = segment {
        return textSegment.content
      }
      return nil
    }
    .joined(separator: " ")
  }
}
