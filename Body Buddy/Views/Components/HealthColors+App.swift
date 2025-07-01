//
//  HealthColors+App.swift
//  Body Buddy
//
//  Created by Rudrank Riyam on 7/1/25.
//

import SwiftUI

// MARK: - Health Colors
extension Color {
    // Primary Colors
    static let healthPrimary = Color(red: 0.0, green: 0.62, blue: 0.57) // Mint green
    static let healthSecondary = Color(red: 0.0, green: 0.48, blue: 1.0) // Blue
    static let healthAccent = Color(red: 1.0, green: 0.62, blue: 0.0) // Orange
    
    // Health Metric Colors
    static let heartColor = Color(red: 0.91, green: 0.26, blue: 0.21) // Red
    static let stepsColor = Color(red: 0.0, green: 0.73, blue: 0.42) // Green
    static let sleepColor = Color(red: 0.48, green: 0.0, blue: 0.73) // Purple
    static let caloriesColor = Color(red: 1.0, green: 0.62, blue: 0.0) // Orange
    static let mindfulnessColor = Color(red: 0.0, green: 0.73, blue: 0.62) // Calm teal
    
    // Status Colors
    static let successGreen = Color(red: 0.2, green: 0.78, blue: 0.35)
    static let warningYellow = Color(red: 1.0, green: 0.8, blue: 0.0)
    static let alertRed = Color(red: 0.91, green: 0.26, blue: 0.21)
    
    // Background Colors
    static let lightBackground = Color(red: 0.97, green: 0.98, blue: 0.99)
    static let darkBackground = Color(red: 0.11, green: 0.11, blue: 0.14)
}

// MARK: - Gradient Extensions
extension LinearGradient {
    static let healthGradient = LinearGradient(
        colors: [.healthPrimary, .healthSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let heartGradient = LinearGradient(
        colors: [.heartColor, .heartColor.opacity(0.8)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let activityGradient = LinearGradient(
        colors: [.stepsColor, .stepsColor.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let sleepGradient = LinearGradient(
        colors: [.sleepColor.opacity(0.8), .sleepColor],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let energyGradient = LinearGradient(
        colors: [.caloriesColor, .caloriesColor.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Metric Type Extensions
extension MetricType {
    var themeColor: Color {
        switch self {
        case .steps: return .stepsColor
        case .heartRate: return .heartColor
        case .sleep: return .sleepColor
        case .activeEnergy: return .caloriesColor
        case .distance: return .healthSecondary
        case .weight: return Color.brown
        case .bloodPressure: return .heartColor.opacity(0.8)
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