//
//  HealthDashboardView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/23/25.
//

import SwiftUI
import SwiftData
import FoundationModels

struct HealthDashboardView: View {
    @Query(sort: \HealthMetric.timestamp, order: .reverse) private var metrics: [HealthMetric]
    @Query(sort: \HealthInsight.generatedAt, order: .reverse) private var insights: [HealthInsight]
    @State private var selectedMetricType: MetricType?
    @State private var showingBuddyChat = false
    @State private var isLoading = true
    @State private var healthDataManager = HealthDataManager.shared
    @Environment(\.modelContext) private var modelContext
    @Namespace private var animationNamespace

    @State private var todayMetrics: [MetricType: Double] = [:]
    @State private var encouragementMessage = "Loading your health insights..."
    @State private var isGeneratingMessage = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView("Loading health data...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                } else {
                    headerSection

                    dailyProgressSection

                    metricsGridSection

                    insightsSection
                }
            }
            .padding()
        }
        .navigationTitle("Health Dashboard")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingBuddyChat = true
                } label: {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .foregroundStyle(.primary)
                }
            }
            #else
            ToolbarItem(placement: .automatic) {
                Button {
                    showingBuddyChat = true
                } label: {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .foregroundStyle(.primary)
                }
            }
            #endif
        }
        .sheet(isPresented: $showingBuddyChat) {
            HealthChatView()
        }
        .task {
            await loadHealthData()
        }
        .refreshable {
            await loadHealthData()
        }
        .onChange(of: todayMetrics) { _, _ in
            Task {
                await generateEncouragementMessage()
            }
        }
    }

}

private extension HealthDashboardView {
    var headerSection: some View {
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

            Text(encouragementMessage)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding()
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    var dailyProgressSection: some View {
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
                        .glassEffect(.regular, in: .rect(cornerRadius: 16))
                    }
                }
            }
        }
    }

    var metricsGridSection: some View {
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

    var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AI Insights")
                    .font(.headline)

                Spacer()

                if !insights.isEmpty {
                    let unreadCount = insights.filter { !$0.isRead }.count
                    if unreadCount > 0 {
                        Text("\(unreadCount) new")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.primary.opacity(0.08))
                            .clipShape(Capsule())
                    }
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

    var timeOfDay: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "morning"
        case 12..<17: return "afternoon"
        default: return "evening"
        }
    }

    func calculateHealthScore() -> Double {
        let stepsScore = min((todayMetrics[.steps] ?? 0) / MetricType.steps.defaultGoal, 1.0)
        let sleepScore = min((todayMetrics[.sleep] ?? 0) / MetricType.sleep.defaultGoal, 1.0)
        let activityScore = min((todayMetrics[.activeEnergy] ?? 0) / MetricType.activeEnergy.defaultGoal, 1.0)

        return (stepsScore + sleepScore + activityScore) / 3.0 * 100
    }
}

@MainActor
private extension HealthDashboardView {
    func generateEncouragementMessage() async {
        guard !isGeneratingMessage else { return }
        isGeneratingMessage = true

        let score = calculateHealthScore()
        let stepsProgress = (todayMetrics[.steps] ?? 0) / MetricType.steps.defaultGoal * 100
        let sleepHours = todayMetrics[.sleep] ?? 0
        let activeEnergy = Int(todayMetrics[.activeEnergy] ?? 0)

        do {
            let session = LanguageModelSession(
                instructions: Instructions(
                    """
                    You are a supportive health coach.
                    Generate a brief, encouraging message (max 15 words) based on the user's health data.
                    Do NOT use quotes, numbers, specific metrics, or emojis.
                    Focus on general encouragement and motivation.
                    """
                )
            )

            let prompt = """
                Health Score: \(Int(score))/100
                Steps Progress: \(Int(stepsProgress))% of daily goal
                Sleep: \(String(format: "%.1f", sleepHours)) hours last night
                Active Energy: \(activeEnergy) calories burned today
                Time of Day: \(timeOfDay)

                Generate a personalized, encouraging message.
                """

            let response = try await session.respond(to: Prompt(prompt))

            encouragementMessage = response.content
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\"", with: "")
                .replacingOccurrences(of: "\u{201C}", with: "")
                .replacingOccurrences(of: "\u{201D}", with: "")
        } catch {
            encouragementMessage = score >= 75 ? "Great progress today!" : "Keep working towards your goals!"
        }

        isGeneratingMessage = false
    }

    func loadHealthData() async {
        healthDataManager.configureModelContext(modelContext)

        if !healthDataManager.isAuthorized {
            do {
                try await healthDataManager.requestAuthorization()
            } catch {
                isLoading = false
                return
            }
        }

        await healthDataManager.fetchTodayHealthData()

        todayMetrics = [
            .steps: healthDataManager.todaySteps,
            .heartRate: healthDataManager.currentHeartRate,
            .sleep: healthDataManager.lastNightSleep,
            .activeEnergy: healthDataManager.todayActiveEnergy,
            .distance: healthDataManager.todayDistance
        ]

        isLoading = false

        await generateEncouragementMessage()
    }
}

// MARK: - Health Score Ring
struct HealthScoreRing: View {
    let score: Double
    @State private var animatedScore: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.1), lineWidth: 6)

            Circle()
                .trim(from: 0, to: animatedScore / 100)
                .stroke(
                    Color.primary,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 1.5), value: animatedScore)

            VStack(spacing: 2) {
                Text("\(Int(animatedScore))")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text("Score")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            animatedScore = score
        }
    }
}

// MARK: - Placeholder View
struct InsightPlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("No insights yet")
                .font(.subheadline)
                .fontWeight(.medium)

            Text("Start tracking your health metrics to receive personalized AI insights")
                .font(.caption)
                .foregroundStyle(.tertiary)
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
