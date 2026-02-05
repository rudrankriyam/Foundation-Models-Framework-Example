//
//  MetricCardView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/23/25.
//

import SwiftUI

struct MetricCardView: View {
    let metricType: MetricType
    let value: Double
    let isSelected: Bool
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: metricType.icon)
                    .font(.body)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .frame(width: 24, height: 24)

                Spacer()
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text(formattedValue)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(metricType.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassEffect(
            .regular,
            in: .rect(cornerRadius: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.primary.opacity(0.2) : Color.clear, lineWidth: 1)
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(metricType.rawValue): \(formattedValue)")
        .accessibilityValue(isSelected ? "Selected" : "")
    }

    private var formattedValue: String {
        switch metricType {
        case .steps, .activeEnergy:
            return "\(Int(value))"
        case .heartRate:
            return "\(Int(value)) bpm"
        case .sleep:
            return String(format: "%.1f hrs", value)
        case .distance:
            return String(format: "%.1f km", value)
        case .weight:
            return String(format: "%.1f kg", value)
        case .bloodPressure:
            return "\(Int(value))/80"
        case .bloodOxygen:
            return "\(Int(value))%"
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 16) {
            MetricCardView(metricType: .steps, value: 8432, isSelected: false)
            MetricCardView(metricType: .heartRate, value: 72, isSelected: true)
        }

        HStack(spacing: 16) {
            MetricCardView(metricType: .sleep, value: 7.5, isSelected: false)
            MetricCardView(metricType: .activeEnergy, value: 412, isSelected: false)
        }
    }
    .padding()
}
