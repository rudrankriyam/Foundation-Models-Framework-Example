//
//  HealthInsight.swift
//  Body Buddy
//
//  Created by Rudrank Riyam on 6/23/25.
//

import Foundation
import SwiftData

@Model
final class HealthInsight {
    var id: UUID
    var title: String
    var content: String
    var category: InsightCategory
    var priority: InsightPriority
    var relatedMetrics: [MetricType]
    var generatedAt: Date
    var isRead: Bool
    var actionItems: [String]
    
    init(title: String, content: String, category: InsightCategory, priority: InsightPriority = .medium, relatedMetrics: [MetricType] = [], actionItems: [String] = []) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.category = category
        self.priority = priority
        self.relatedMetrics = relatedMetrics
        self.generatedAt = Date()
        self.isRead = false
        self.actionItems = actionItems
    }
}

enum InsightCategory: String, Codable, CaseIterable {
    case trend = "Trend Analysis"
    case achievement = "Achievement"
    case recommendation = "Recommendation"
    case warning = "Health Warning"
    case goal = "Goal Progress"
    case comparison = "Comparison"
    
    var icon: String {
        switch self {
        case .trend: return "chart.line.uptrend.xyaxis"
        case .achievement: return "trophy.fill"
        case .recommendation: return "lightbulb.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .goal: return "target"
        case .comparison: return "chart.bar.fill"
        }
    }
}

enum InsightPriority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .urgent: return "red"
        }
    }
}