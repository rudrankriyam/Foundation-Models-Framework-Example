//
//  PerformanceMetrics.swift
//  FMF
//
//  Created by AI Assistant on 6/9/25.
//

import Foundation
import Observation

/// Model for tracking performance metrics of language model operations
@Observable
final class PerformanceMetrics {

  // MARK: - Properties

  var startTime: Date?
  var endTime: Date?
  var totalTokens: Int = 0
  var streamingTokens: [StreamingTokenData] = []
  var operationType: OperationType = .basic
  var promptLength: Int = 0

  // MARK: - Computed Properties

  var duration: TimeInterval {
    guard let startTime = startTime,
      let endTime = endTime
    else { return 0 }
    return endTime.timeIntervalSince(startTime)
  }

  var tokensPerSecond: Double {
    guard duration > 0, totalTokens > 0 else { return 0 }
    return Double(totalTokens) / duration
  }

  var tokensPerMinute: Double {
    return tokensPerSecond * 60
  }

  var averageTokensPerSecond: Double {
    guard !streamingTokens.isEmpty else { return tokensPerSecond }

    let validIntervals = streamingTokens.compactMap { tokenData -> Double? in
      guard tokenData.interval > 0 else { return nil }
      return 1.0 / tokenData.interval
    }

    guard !validIntervals.isEmpty else { return tokensPerSecond }
    return validIntervals.reduce(0, +) / Double(validIntervals.count)
  }

  var averageTokensPerMinute: Double {
    return averageTokensPerSecond * 60
  }

  var isActive: Bool {
    return startTime != nil && endTime == nil
  }

  // MARK: - Methods

  func startTracking(operationType: OperationType, promptLength: Int) {
    self.operationType = operationType
    self.promptLength = promptLength
    self.startTime = Date()
    self.endTime = nil
    self.totalTokens = 0
    self.streamingTokens.removeAll()
  }

  func addStreamingToken(at timestamp: Date) {
    guard let startTime = startTime else { return }

    let interval =
      streamingTokens.last?.timestamp.timeIntervalSince(timestamp)
      ?? timestamp.timeIntervalSince(startTime)

    streamingTokens.append(
      StreamingTokenData(
        timestamp: timestamp,
        interval: abs(interval),
        cumulativeTokens: streamingTokens.count + 1
      ))
  }

  func finishTracking(totalTokens: Int) {
    self.endTime = Date()
    self.totalTokens = max(totalTokens, streamingTokens.count)
  }

  func reset() {
    startTime = nil
    endTime = nil
    totalTokens = 0
    streamingTokens.removeAll()
    operationType = .basic
    promptLength = 0
  }

  // MARK: - Debug Description

  var debugDescription: String {
    var description = "Performance Metrics:\n"
    description += "Operation: \(operationType.displayName)\n"
    description += "Prompt Length: \(promptLength) characters\n"
    description += "Duration: \(String(format: "%.2f", duration))s\n"
    description += "Total Tokens: \(totalTokens)\n"
    description += "Tokens/Second: \(String(format: "%.1f", tokensPerSecond))\n"
    description += "Tokens/Minute: \(String(format: "%.0f", tokensPerMinute))\n"

    if !streamingTokens.isEmpty {
      description += "Avg Tokens/Second: \(String(format: "%.1f", averageTokensPerSecond))\n"
      description += "Avg Tokens/Minute: \(String(format: "%.0f", averageTokensPerMinute))\n"
      description += "Streaming Samples: \(streamingTokens.count)\n"
    }

    return description
  }
}

// MARK: - Supporting Types

struct StreamingTokenData {
  let timestamp: Date
  let interval: TimeInterval
  let cumulativeTokens: Int
}

enum OperationType {
  case basic
  case structured
  case streaming
  case toolCalling
  case creative
  case business

  var displayName: String {
    switch self {
    case .basic: return "Basic Chat"
    case .structured: return "Structured Data"
    case .streaming: return "Streaming"
    case .toolCalling: return "Tool Calling"
    case .creative: return "Creative Writing"
    case .business: return "Business Ideas"
    }
  }
}
