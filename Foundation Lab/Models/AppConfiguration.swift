//
//  AppConfiguration.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 11/7/25.
//

import Foundation

/// Centralized configuration constants for the app
enum AppConfiguration {
    /// Token management configuration
    enum TokenManagement {
        /// Maximum tokens allowed in context window
        static let maxTokens = 4096

        /// Threshold percentage (0.0-1.0) at which to start applying sliding window
        static let windowThreshold = 0.75

        /// Target window size in tokens after applying sliding window
        static let targetWindowSize = 2000
    }

    /// Health module configuration
    enum Health {
        /// Session timeout in seconds (1 hour)
        static let sessionTimeoutHours: TimeInterval = 3600
    }
}
