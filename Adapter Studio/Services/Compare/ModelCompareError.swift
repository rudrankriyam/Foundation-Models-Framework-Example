//
//  ModelCompareError.swift
//  Adapter Studio
//
//  Created by Rudrank Riyam on 10/22/25.
//

import Foundation

/// Lightweight error payload surfaced by ``ModelCompareEngine``.
struct ModelCompareError: Sendable {

    /// Localized description suitable for UI alerts and toasts.
    let message: String
}
