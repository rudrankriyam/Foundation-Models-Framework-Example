//
//  SessionColumnView.swift
//  Adapter Studio
//
//  Created by Rudrank Riyam on 10/22/25.
//

import SwiftUI

/// Renders the streaming output for one side of the comparison.
struct SessionColumnView: View {
    let title: String
    let subtitle: String
    let column: CompareViewModel.ColumnState
    let isActive: Bool

    private let cornerRadius: CGFloat = 18

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            responseBody
            metricsSection
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 360, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.035))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(.primary, lineWidth: 1)
                )
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))

            Text(subtitle)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))
        }
    }

    @ViewBuilder
    private var responseBody: some View {
        ScrollView {
            if column.text.isEmpty {
                placeholder
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
            } else {
                Text(column.text)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(.vertical, 4)
            }
        }
        .frame(minHeight: 220)
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private var metricsSection: some View {
        if let metrics = column.metrics {
            HStack(spacing: 8) {
                if let ttf = metrics.timeToFirstToken {
                    MetricBadge(icon: "bolt.fill", title: "First token", value: formattedDuration(ttf))
                }

                if let duration = metrics.totalDuration {
                    MetricBadge(icon: "clock", title: "Total", value: formattedDuration(duration))
                }

                MetricBadge(
                    icon: "calendar",
                    title: "Started",
                    value: metrics.startedAt.formatted(date: .omitted, time: .standard)
                )
            }
        } else if isActive {
            ProgressView()
                .progressViewStyle(.circular)
        }
    }

    private var placeholder: some View {
        VStack(alignment: .leading, spacing: 10) {
            if isActive {
                HStack(spacing: 10) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.9)

                    Text("Streaming response…")
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.65))
                }
            } else {
                Text("Awaiting prompt")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    private func formattedDuration(_ value: TimeInterval) -> String {
        let formatted = value.formatted(.number.precision(.fractionLength(2)))
        return "\(formatted)s"
    }
}

private struct MetricBadge: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.85))
                .padding(6)
                .background(
                    Circle()
                        .fill(.primary.opacity(0.35))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.55))
                Text(value)
                    .font(.caption)
                    .foregroundStyle(.white)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }
}

#Preview {
    SessionColumnView(
        title: "Base",
        subtitle: "System Language Model",
        column: .init(text: "Example streaming output", metrics: .init(startedAt: .now)),
        isActive: false
    )
    .frame(width: 420)
    .padding()
    .background(Color.black)
}
