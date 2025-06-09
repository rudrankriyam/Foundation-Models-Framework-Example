//
//  DebugPerformanceView.swift
//  FMF
//
//  Created by AI Assistant on 6/9/25.
//

import SwiftUI

struct DebugPerformanceView: View {
  let metrics: PerformanceMetrics
  let onReset: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      headerView

      if metrics.isActive {
        activeTrackingView
      } else if metrics.duration > 0 {
        completedMetricsView
      } else {
        noDataView
      }
    }
    .padding()
    .background(.ultraThinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .padding(.horizontal)
  }

  // MARK: - View Components

  private var headerView: some View {
    HStack {
      Image(systemName: "speedometer")
        .foregroundColor(.blue)
        .font(.title2)

      VStack(alignment: .leading, spacing: 2) {
        Text("Performance Debug")
          .font(.headline)
          .fontWeight(.semibold)

        if metrics.duration > 0 || metrics.isActive {
          Text(metrics.operationType.displayName)
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      Spacer()

      if metrics.duration > 0 {
        Button("Reset", action: onReset)
          .font(.caption)
          .foregroundColor(.blue)
      }
    }
  }

  private var activeTrackingView: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        ProgressView()
          .scaleEffect(0.8)
        Text("Tracking performance...")
          .font(.subheadline)
          .foregroundColor(.secondary)
      }

      if !metrics.streamingTokens.isEmpty {
        Text("Streaming tokens: \(metrics.streamingTokens.count)")
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
  }

  private var completedMetricsView: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Key metrics row
      HStack(spacing: 24) {
        MetricView(
          title: "Tokens/Min",
          value: String(format: "%.0f", metrics.tokensPerMinute),
          icon: "clock",
          color: .green
        )

        MetricView(
          title: "Duration",
          value: String(format: "%.2fs", metrics.duration),
          icon: "timer",
          color: .blue
        )

        MetricView(
          title: "Total Tokens",
          value: "\(metrics.totalTokens)",
          icon: "text.bubble",
          color: .orange
        )
      }

      Divider()

      // Detailed metrics
      detailedMetricsView

      if !metrics.streamingTokens.isEmpty {
        Divider()
        streamingMetricsView
      }

      Divider()

      Text("Token counts are estimated using OpenAI's guidelines (1 token ≈ 4 chars or 0.75 words)")
        .font(.caption2)
        .foregroundColor(.tertiary)
        .italic()
    }
  }

  private var detailedMetricsView: some View {
    VStack(alignment: .leading, spacing: 6) {
      DetailRow(label: "Tokens/Second", value: String(format: "%.1f", metrics.tokensPerSecond))
      DetailRow(label: "Prompt Length", value: "\(metrics.promptLength) chars")

      if metrics.tokensPerMinute > 0 {
        let performance = getPerformanceRating(tokensPerMinute: metrics.tokensPerMinute)
        DetailRow(label: "Performance", value: performance.description, color: performance.color)
      }
    }
  }

  private var streamingMetricsView: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Streaming Analysis")
        .font(.subheadline)
        .fontWeight(.medium)

      DetailRow(
        label: "Avg Tokens/Min",
        value: String(format: "%.0f", metrics.averageTokensPerMinute)
      )
      DetailRow(
        label: "Token Samples",
        value: "\(metrics.streamingTokens.count)"
      )

      if let firstToken = metrics.streamingTokens.first,
        let lastToken = metrics.streamingTokens.last
      {
        let streamDuration = lastToken.timestamp.timeIntervalSince(firstToken.timestamp)
        DetailRow(
          label: "Stream Duration",
          value: String(format: "%.2fs", streamDuration)
        )
      }
    }
  }

  private var noDataView: some View {
    VStack(spacing: 8) {
      Image(systemName: "chart.line.uptrend.xyaxis")
        .font(.title2)
        .foregroundColor(.secondary)

      Text("No performance data yet")
        .font(.subheadline)
        .foregroundColor(.secondary)

      Text("Run an operation to see metrics")
        .font(.caption)
        .foregroundStyle(.tertiary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical)
  }
}

// MARK: - Supporting Views

struct MetricView: View {
  let title: String
  let value: String
  let icon: String
  let color: Color

  var body: some View {
    VStack(spacing: 4) {
      Image(systemName: icon)
        .foregroundColor(color)
        .font(.title3)

      Text(value)
        .font(.headline)
        .fontWeight(.semibold)

      Text(title)
        .font(.caption2)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity)
  }
}

struct DetailRow: View {
  let label: String
  let value: String
  var color: Color = .primary

  var body: some View {
    HStack {
      Text(label)
        .font(.caption)
        .foregroundColor(.secondary)

      Spacer()

      Text(value)
        .font(.caption)
        .fontWeight(.medium)
        .foregroundColor(color)
    }
  }
}

// MARK: - Helper Functions

private func getPerformanceRating(tokensPerMinute: Double) -> (description: String, color: Color) {
  switch tokensPerMinute {
  case 0..<300:
    return ("Slow", .red)
  case 300..<600:
    return ("Fair", .orange)
  case 600..<1200:
    return ("Good", .yellow)
  case 1200..<2400:
    return ("Excellent", .green)
  default:
    return ("Outstanding", .blue)
  }
}

// MARK: - Preview

#Preview {
  VStack(spacing: 20) {
    // Active tracking preview
    DebugPerformanceView(
      metrics: {
        let metrics = PerformanceMetrics()
        metrics.startTracking(operationType: .streaming, promptLength: 150)
        metrics.addStreamingToken(at: Date())
        return metrics
      }(),
      onReset: {}
    )

    // Completed metrics preview
    DebugPerformanceView(
      metrics: {
        let metrics = PerformanceMetrics()
        metrics.startTracking(operationType: .basic, promptLength: 85)
        Thread.sleep(forTimeInterval: 0.1)  // Simulate some time
        metrics.finishTracking(totalTokens: 42)
        return metrics
      }(),
      onReset: {}
    )

    // No data preview
    DebugPerformanceView(
      metrics: PerformanceMetrics(),
      onReset: {}
    )
  }
  .padding()
  .background(Color.gray.opacity(0.1))
}
