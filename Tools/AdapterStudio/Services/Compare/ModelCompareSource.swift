//
//  ModelCompareSource.swift
//  Adapter Studio
//
//  Created by Rudrank Riyam on 10/22/25.
//

import Foundation

/// Identifies which model produced a streaming update during a comparison run.
enum ModelCompareSource: String, Sendable {

    /// The baseline `SystemLanguageModel`.
    case base

    /// The adapter-backed `SystemLanguageModel`.
    case adapter

    /// Human-friendly name for UI presentation.
    var displayName: String {
        switch self {
        case .base: "Base"
        case .adapter: "Adapter"
        }
    }
}
