//
//  MetricCardView.swift
//  Body Buddy
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: metricType.icon)
                    .font(.title2)
                    .foregroundStyle(metricType.themeColor)
                    .frame(width: 30, height: 30)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(180))
                }
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(metricType.themeColor.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? metricType.themeColor : Color.clear, lineWidth: 2)
        )
        .glassEffect(
            isSelected ? .regular.tint(metricType.themeColor) : .regular,
            in: .rect(cornerRadius: 16)
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .shadow(
            color: isSelected ? metricType.themeColor.opacity(0.3) : .clear,
            radius: 10
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                isAnimating = true
            }
        }
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