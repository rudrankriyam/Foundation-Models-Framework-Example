//
//  Color+Extensions.swift
//  FoundationLabsKit
//
//  Created by Rudrank Riyam on 7/1/25.
//

import SwiftUI

// MARK: - Common Color Extensions
public extension Color {
    /// Secondary background color that adapts to the platform
    static var secondaryBackgroundColor: Color {
        #if os(iOS)
        Color(UIColor.secondarySystemBackground)
        #elseif os(macOS)
        Color(NSColor.controlBackgroundColor)
        #else
        Color.gray.opacity(0.1)
        #endif
    }
    
    /// Tertiary background color that adapts to the platform
    static var tertiaryBackgroundColor: Color {
        #if os(iOS)
        Color(UIColor.tertiarySystemBackground)
        #elseif os(macOS)
        Color(NSColor.controlBackgroundColor).opacity(0.5)
        #else
        Color.gray.opacity(0.05)
        #endif
    }
    
    // MARK: - Glass Tint Colors
    static let glassTintLight = Color.white.opacity(0.3)
    static let glassTintDark = Color.black.opacity(0.2)
}

// MARK: - App Color Protocol
/// Protocol for defining app-specific color schemes
public protocol AppColorScheme {
    static var primary: Color { get }
    static var secondary: Color { get }
    static var accent: Color { get }
}

// MARK: - Health Colors Namespace
/// Namespace for health-related colors to avoid polluting the global Color namespace
public struct HealthColors {
    // MARK: - Primary Health Colors
    public static let primary = Color(red: 0.0, green: 0.78, blue: 0.88) // Bright cyan
    public static let secondary = Color(red: 0.44, green: 0.86, blue: 0.58) // Fresh green
    public static let accent = Color(red: 1.0, green: 0.45, blue: 0.42) // Warm coral
    
    // MARK: - Metric-Specific Colors
    public static let heart = Color(red: 0.91, green: 0.12, blue: 0.31) // Heart red
    public static let steps = Color(red: 0.0, green: 0.48, blue: 1.0) // Activity blue
    public static let sleep = Color(red: 0.58, green: 0.39, blue: 0.87) // Sleep purple
    public static let calories = Color(red: 1.0, green: 0.58, blue: 0.0) // Energy orange
    public static let mindfulness = Color(red: 0.0, green: 0.73, blue: 0.62) // Calm teal
    
    // MARK: - Status Colors
    public static let success = Color(red: 0.2, green: 0.78, blue: 0.35)
    public static let warning = Color(red: 1.0, green: 0.8, blue: 0.0)
    public static let alert = Color(red: 0.91, green: 0.26, blue: 0.21)
    
    // MARK: - Background Colors
    public static let lightBackground = Color(red: 0.97, green: 0.98, blue: 0.99)
    public static let darkBackground = Color(red: 0.11, green: 0.11, blue: 0.14)
}