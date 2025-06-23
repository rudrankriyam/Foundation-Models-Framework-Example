//
//  HealthDashboardView.swift
//  Body Buddy
//
//  Created by Rudrank Riyam on 6/23/25.
//

import SwiftUI
import SwiftData

struct HealthDashboardView: View {
    @Query(sort: \HealthMetric.timestamp, order: .reverse) private var metrics: [HealthMetric]
    @Query(sort: \HealthInsight.generatedAt, order: .reverse) private var insights: [HealthInsight]
    @State private var selectedMetricType: MetricType? = nil
    @State private var showingBuddyChat = false
    @Namespace private var animationNamespace
    
    // Mock data for now - will be replaced with real HealthKit data
    @State private var todayMetrics: [MetricType: Double] = [
        .steps: 6842,
        .heartRate: 72,
        .sleep: 7.5,
        .activeEnergy: 342
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                
                dailyProgressSection
                
                metricsGridSection
                
                insightsSection
            }
            .padding()
        }
        .background(Color.lightBackground.ignoresSafeArea())
        .navigationTitle("Health Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingBuddyChat = true
                } label: {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .foregroundStyle(Color.healthPrimary)
                }
            }
        }
        .sheet(isPresented: $showingBuddyChat) {
            // BuddyChatView() - Will implement later
            Text("Buddy Chat Coming Soon!")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Good \(timeOfDay)!")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Your health score today")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    HealthScoreRing(score: calculateHealthScore())
                        .frame(width: 80, height: 80)
                }
                
            Text("You're doing great! Keep up the good work.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding()
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }
    
    // MARK: - Daily Progress Section
    private var dailyProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Progress")
                .font(.headline)
                .padding(.horizontal, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach([MetricType.steps, .activeEnergy, .sleep], id: \.self) { type in
                        DailyProgressCard(
                            metricType: type,
                            currentValue: todayMetrics[type] ?? 0,
                            goalValue: type.defaultGoal,
                            animationNamespace: animationNamespace
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Metrics Grid Section
    private var metricsGridSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Health Metrics")
                .font(.headline)
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                ForEach(MetricType.allCases, id: \.self) { type in
                    MetricCardView(
                        metricType: type,
                        value: todayMetrics[type] ?? 0,
                        isSelected: selectedMetricType == type
                    )
                    .onTapGesture {
                        withAnimation(.spring()) {
                            selectedMetricType = selectedMetricType == type ? nil : type
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Insights Section
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AI Insights")
                    .font(.headline)
                
                Spacer()
                
                if !insights.isEmpty {
                    Text("\(insights.filter { !$0.isRead }.count) new")
                        .font(.caption)
                        .foregroundStyle(Color.healthPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.healthPrimary.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 4)
            
            if insights.isEmpty {
                InsightPlaceholderView()
            } else {
                ForEach(insights.prefix(3)) { insight in
                    InsightCardView(insight: insight)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private var timeOfDay: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "morning"
        case 12..<17: return "afternoon"
        default: return "evening"
        }
    }
    
    private func calculateHealthScore() -> Double {
        // Simple health score calculation - will be improved with AI
        let stepsScore = min((todayMetrics[.steps] ?? 0) / MetricType.steps.defaultGoal, 1.0)
        let sleepScore = min((todayMetrics[.sleep] ?? 0) / MetricType.sleep.defaultGoal, 1.0)
        let activityScore = min((todayMetrics[.activeEnergy] ?? 0) / MetricType.activeEnergy.defaultGoal, 1.0)
        
        return (stepsScore + sleepScore + activityScore) / 3.0 * 100
    }
}

// MARK: - Health Score Ring
struct HealthScoreRing: View {
    let score: Double
    @State private var animatedScore: Double = 0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
            
            Circle()
                .trim(from: 0, to: animatedScore / 100)
                .stroke(
                    scoreGradient,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 1.5), value: animatedScore)
            
            VStack(spacing: 2) {
                Text("\(Int(animatedScore))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(scoreColor)
                
                Text("Score")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            animatedScore = score
        }
    }
    
    private var scoreGradient: LinearGradient {
        LinearGradient(
            colors: [scoreColor, scoreColor.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var scoreColor: Color {
        switch score {
        case 80...: return .successGreen
        case 60..<80: return .warningYellow
        default: return .alertRed
        }
    }
}

// MARK: - Placeholder View
struct InsightPlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.largeTitle)
                .foregroundStyle(Color.healthPrimary)
            
            Text("No insights yet")
                .font(.headline)
            
            Text("Start tracking your health metrics to receive personalized AI insights")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }
}

// MARK: - MetricType Extension
extension MetricType {
    var defaultGoal: Double {
        switch self {
        case .steps: return 10000
        case .heartRate: return 80
        case .sleep: return 8
        case .activeEnergy: return 500
        case .distance: return 5
        case .weight: return 70
        case .bloodPressure: return 120
        case .bloodOxygen: return 98
        }
    }
}

#Preview {
    NavigationStack {
        HealthDashboardView()
            .modelContainer(for: [HealthMetric.self, HealthInsight.self])
    }
}