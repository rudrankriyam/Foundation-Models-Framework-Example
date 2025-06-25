//
//  OpenChatIntent.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/25/25.
//

import AppIntents
import SwiftUI

struct OpenChatIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Chat"
    static var description = IntentDescription("Opens the FMF chat interface")
    
    static var supportedModes: IntentModes = .foreground

    @MainActor
    func perform() async throws -> some IntentResult {
        NavigationCoordinator.shared.navigate(to: .chat)
        return .result()
    }
}
