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
  /// Tool calls and tool outputs before the most recent assistant response or
  /// tool-call entry are removed. The most recent response/tool-call entry and
  /// everything after it is preserved.
  ///
  /// This keeps old tool chatter from growing context while retaining the latest
  /// active tool exchange.
  public func droppingCompletedToolCalls() -> [Transcript.Entry] {
    let entries = Array(self)

    guard !entries.isEmpty else {
      return []
    }

    let lastOutputIndex =
      entries.lastIndex { entry in
        if case .response = entry { return true }
        if case .toolCalls = entry { return true }
        return false
      } ?? entries.startIndex

    let prefix = entries[..<lastOutputIndex].filter { entry in
      if case .toolCalls = entry { return false }
      if case .toolOutput = entry { return false }
      return true
    }

    let suffix = entries[lastOutputIndex...]
    return Array(prefix + suffix)
  }
}
