//
//  HealthColors+App.swift
//  Body Buddy
//
//  Created by Rudrank Riyam on 7/1/25.
//

import SwiftUI
// When using as remote dependency:
// import FoundationLabsKit

// MARK: - Legacy Health Color Mappings
// These extensions map the old color names to the new HealthColors namespace
extension Color {
    static let healthPrimary = HealthColors.primary
    static let healthSecondary = HealthColors.secondary
    static let healthAccent = HealthColors.accent
    static let heartColor = HealthColors.heart
    static let stepsColor = HealthColors.steps
    static let sleepColor = HealthColors.sleep
    static let caloriesColor = HealthColors.calories
    static let mindfulnessColor = HealthColors.mindfulness
    static let successGreen = HealthColors.success
    static let warningYellow = HealthColors.warning
    static let alertRed = HealthColors.alert
    static let lightBackground = HealthColors.lightBackground
    static let darkBackground = HealthColors.darkBackground
}

// MARK: - Gradient Extensions
extension LinearGradient {
    static let healthGradient = LinearGradient(
        colors: [HealthColors.primary, HealthColors.secondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let heartGradient = LinearGradient(
        colors: [HealthColors.heart, HealthColors.heart.opacity(0.8)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let activityGradient = LinearGradient(
        colors: [HealthColors.steps, HealthColors.steps.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let sleepGradient = LinearGradient(
        colors: [HealthColors.sleep.opacity(0.8), HealthColors.sleep],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let energyGradient = LinearGradient(
        colors: [HealthColors.calories, HealthColors.calories.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Metric Type Extensions
extension MetricType {
    var themeColor: Color {
        switch self {
        case .steps: return HealthColors.steps
        case .heartRate: return HealthColors.heart
        case .sleep: return HealthColors.sleep
        case .activeEnergy: return HealthColors.calories
        case .distance: return HealthColors.secondary
        case .weight: return Color.brown
        case .bloodPressure: return HealthColors.heart.opacity(0.8)
        case .bloodOxygen: return Color.cyan
        }
    }
    
    var gradient: LinearGradient {
        switch self {
        case .steps: return .activityGradient
        case .heartRate: return .heartGradient
        case .sleep: return .sleepGradient
        case .activeEnergy: return .energyGradient
        default: return .healthGradient
        }
    }
}