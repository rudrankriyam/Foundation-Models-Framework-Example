//
//  OpenChatIntent.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/25/25.
//

import AppIntents
import SwiftUI

nonisolated struct OpenChatIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Foundation Lab Examples"
    static let description = IntentDescription("Opens the FoundationLab examples section")

    static let supportedModes: IntentModes = .foreground

    @MainActor
    func perform() async throws -> some IntentResult {
        NavigationCoordinator.shared.navigate(to: .examples)
        return .result()
    }
}
