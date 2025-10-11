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

        AppShortcut(
            intent: QuickPikachuIntent(),
            phrases: [
                "Show Pikachu in \(.applicationName)",
                "Tell me about Pikachu with \(.applicationName)"
            ],
            shortTitle: "Show Pikachu",
            systemImageName: "bolt.fill"
        )

        AppShortcut(
            intent: RandomPokemonIntent(),
            phrases: [
                "Show random Pokemon in \(.applicationName)",
                "Surprise me with a Pokemon in \(.applicationName)"
            ],
            shortTitle: "Random Pokemon",
            systemImageName: "dice"
        )

        AppShortcut(
            intent: LegendaryPokemonIntent(),
            phrases: [
                "Find legendary Pokemon in \(.applicationName)",
                "Show me legendary Pokemon with \(.applicationName)"
            ],
            shortTitle: "Find Legendary",
            systemImageName: "star.fill"
        )
    }

    static var shortcutTileColor: ShortcutTileColor = .orange
}
