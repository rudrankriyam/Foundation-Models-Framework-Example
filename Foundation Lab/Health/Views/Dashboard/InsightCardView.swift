//
//  InsightCardView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/23/25.
//

import SwiftUI
import SwiftData

struct InsightCardView: View {
    let insight: HealthInsight
    @Environment(\.modelContext) private var modelContext
    @State private var isExpanded = false
    @State private var showCelebration = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top) {
                HStack(spacing: 8) {
                    Image(systemName: insight.category.icon)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(width: 20, height: 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(insight.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(isExpanded ? nil : 1)

                        Text(timeAgo(from: insight.generatedAt))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                if !insight.isRead {
                    Circle()
                        .fill(Color.primary.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }

            // Content
            Text(insight.content)
                .font(.callout)
                .foregroundStyle(.primary.opacity(0.8))
                .lineLimit(isExpanded ? nil : 2)
                .animation(.easeInOut, value: isExpanded)

            // Action Items
            if isExpanded && !insight.actionItems.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Action Items")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    ForEach(insight.actionItems, id: \.self) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 4))
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)

                            Text(item)
                                .font(.caption)
                                .foregroundStyle(.primary.opacity(0.8))
                        }
                    }
                }
                .padding(.top, 4)
            }

            // Priority Badge
            if insight.priority == .urgent || insight.priority == .high {
                HStack {
                    Text(insight.priority.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(Capsule())

                    Spacer()

                    if isExpanded {
                        Button {
                            markAsRead()
                        } label: {
                            Text("Got it")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.primary.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(
            .regular,
            in: .rect(cornerRadius: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(insight.isRead ? Color.clear : Color.primary.opacity(0.1), lineWidth: 1)
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isExpanded.toggle()
                if !insight.isRead {
                    markAsRead()
                }
            }
        }
        .overlay(
            Group {
                if showCelebration && insight.category == .achievement {
                    Color.clear.modifier(CelebrationEffect())
                }
            }
        )
    }

    private var categoryColor: Color {
        return .primary
    }

    private var priorityColor: Color {
        return .primary
    }

    private func markAsRead() {
        insight.isRead = true
        if insight.category == .achievement {
            showCelebration = true
        }
        try? modelContext.save()
    }

    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    VStack(spacing: 16) {
        InsightCardView(insight: HealthInsight(
            title: "Great Progress!",
            content: """
            You've exceeded your step goal for 5 days straight. Your cardiovascular health is improving!
            """,
            category: .achievement,
            priority: .high,
            relatedMetrics: [.steps],
            actionItems: ["Keep up the momentum", "Try increasing your daily goal by 500 steps"]
        ))

        InsightCardView(insight: HealthInsight(
            title: "Sleep Pattern Alert",
            content: """
            Your sleep duration has decreased by 15% this week. This might affect your recovery and energy levels.
            """,
            category: .warning,
            priority: .urgent,
            relatedMetrics: [.sleep],
            actionItems: ["Set a consistent bedtime", "Avoid screens 1 hour before sleep", "Try relaxation techniques"]
        ))
    }
    .padding()
    .modelContainer(for: HealthInsight.self, inMemory: true)
}
