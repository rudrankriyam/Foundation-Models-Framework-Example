//
//  OpenChatIntent.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/25/25.
//

import AppIntents
import SwiftUI

nonisolated struct OpenChatIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Foundation Lab Chat"
    static let description = IntentDescription("Opens the Foundation Lab chat experience")

    static let supportedModes: IntentModes = .foreground

    @MainActor
    func perform() async throws -> some IntentResult {
        NavigationCoordinator.shared.openChat()
        return .result()
    }
}
