//
//  OpenChatIntent.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/25/25.
//

import AppIntents
import SwiftUI

nonisolated struct OpenChatIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Chat"
    static let description = IntentDescription("Opens the FoundationLab chat interface")

    static let supportedModes: IntentModes = .foreground

    @MainActor
    func perform() async throws -> some IntentResult {
        NavigationCoordinator.shared.navigate(to: .chat)
        return .result()
    }
}
