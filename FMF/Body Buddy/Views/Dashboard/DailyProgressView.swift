//
//  DailyProgressView.swift
//  Body Buddy
//
//  Created by Rudrank Riyam on 6/23/25.
//

import SwiftUI

struct DailyProgressCard: View {
    let metricType: MetricType
    let currentValue: Double
    let goalValue: Double
    let animationNamespace: Namespace.ID
    @State private var animatedProgress: Double = 0
    
    private var progress: Double {
        min(currentValue / goalValue, 1.0)
    }
    
    private var progressPercentage: Int {
        Int(progress * 100)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: metricType.icon)
                    .font(.title3)
                    .foregroundStyle(metricType.themeColor)
                
                Spacer()
                
                Text("\(progressPercentage)%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(progressColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(metricType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 4) {
                    Text(formattedValue)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("/ \(formattedGoal)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(metricType.gradient)
                        .frame(width: geometry.size.width * animatedProgress, height: 6)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animatedProgress)
                }
            }
            .frame(height: 6)
        }
        .padding()
        .frame(width: 180)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
        .onAppear {
            animatedProgress = progress
        }
    }
    
    private var progressColor: Color {
        switch progress {
        case 0.8...: return .successGreen
        case 0.5..<0.8: return .warningYellow
        default: return .alertRed
        }
    }
    
    private var formattedValue: String {
        switch metricType {
        case .steps, .activeEnergy:
            return "\(Int(currentValue))"
        case .sleep:
            return String(format: "%.1f", currentValue)
        default:
            return "\(Int(currentValue))"
        }
    }
    
    private var formattedGoal: String {
        switch metricType {
        case .steps, .activeEnergy:
            return "\(Int(goalValue))"
        case .sleep:
            return String(format: "%.0f hrs", goalValue)
        default:
            return "\(Int(goalValue))"
        }
    }
}

// MARK: - Activity Rings View
struct ActivityRingsView: View {
    let steps: Double
    let activeEnergy: Double
    let standHours: Int
    
    @State private var animateRings = false
    
    var body: some View {
        ZStack {
            // Stand Ring (Outer)
            ActivityRing(
                progress: Double(standHours) / 12.0,
                color: .healthSecondary,
                lineWidth: 12,
                radius: 60
            )
            
            // Active Energy Ring (Middle)
            ActivityRing(
                progress: activeEnergy / 500,
                color: .caloriesColor,
                lineWidth: 12,
                radius: 45
            )
            
            // Steps Ring (Inner)
            ActivityRing(
                progress: steps / 10000,
                color: .stepsColor,
                lineWidth: 12,
                radius: 30
            )
        }
        .frame(width: 140, height: 140)
        .scaleEffect(animateRings ? 1.0 : 0.8)
        .opacity(animateRings ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
                animateRings = true
            }
        }
    }
}

struct ActivityRing: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    let radius: CGFloat
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
                .frame(width: radius * 2, height: radius * 2)
            
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: radius * 2, height: radius * 2)
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 1.2).delay(0.1), value: animatedProgress)
        }
        .onAppear {
            animatedProgress = min(progress, 1.0)
        }
    }
}

#Preview {
    ScrollView(.horizontal) {
        HStack(spacing: 16) {
            DailyProgressCard(
                metricType: .steps,
                currentValue: 7234,
                goalValue: 10000,
                animationNamespace: Namespace().wrappedValue
            )
            
            DailyProgressCard(
                metricType: .activeEnergy,
                currentValue: 342,
                goalValue: 500,
                animationNamespace: Namespace().wrappedValue
            )
            
            DailyProgressCard(
                metricType: .sleep,
                currentValue: 6.5,
                goalValue: 8,
                animationNamespace: Namespace().wrappedValue
            )
        }
        .padding()
    }
}