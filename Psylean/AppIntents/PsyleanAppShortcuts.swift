//
//  PsyleanAppShortcuts.swift
//  Psylean
//
//  Created by Rudrank Riyam on 26/06/25.
//

import AppIntents

struct PsyleanAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AnalyzePokemonIntent(),
            phrases: [
                "Analyze Pokemon in \(.applicationName)",
                "Get Pokemon info in \(.applicationName)",
                "Tell me about a Pokemon in \(.applicationName)"
            ],
            shortTitle: "Analyze Pokemon",
            systemImageName: "sparkles"
        )
    }
}