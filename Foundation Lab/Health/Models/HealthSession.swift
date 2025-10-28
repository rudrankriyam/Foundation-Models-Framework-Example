//
//  HealthSession.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/23/25.
//

import Foundation
import SwiftData

@Model
final class HealthSession {
    var id: UUID
    var startDate: Date
    var endDate: Date?
    var messages: [BuddyMessage]
    var sessionType: SessionType
    var summary: String?

    init(sessionType: SessionType = .general) {
        self.id = UUID()
        self.startDate = Date()
        self.sessionType = sessionType
        self.messages = []
    }

    func addMessage(_ message: BuddyMessage) {
        messages.append(message)
    }

    func endSession(withSummary summary: String? = nil) {
        self.endDate = Date()
        self.summary = summary
    }
}

@Model
final class BuddyMessage {
    var id: UUID
    var content: String
    var isFromUser: Bool
    var timestamp: Date
    var relatedMetricTypes: [MetricType]

    init(content: String, isFromUser: Bool, relatedMetricTypes: [MetricType] = []) {
        self.id = UUID()
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = Date()
        self.relatedMetricTypes = relatedMetricTypes
    }
}

enum SessionType: String, Codable, CaseIterable {
    case general = "General Chat"
    case healthCheck = "Health Check-in"
    case goalSetting = "Goal Setting"
    case analysis = "Health Analysis"
    case coaching = "Coaching Session"

    var icon: String {
        switch self {
        case .general: return "bubble.left.and.bubble.right.fill"
        case .healthCheck: return "heart.text.square.fill"
        case .goalSetting: return "target"
        case .analysis: return "chart.xyaxis.line"
        case .coaching: return "person.fill.questionmark"
        }
    }
}
