//
//  FoundationLabAppShortcuts.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/25/25.
//

import AppIntents

nonisolated struct FoundationLabAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GenerateBookRecommendationIntent(),
            phrases: [
                "Recommend a book in \(.applicationName)",
                "Get a book recommendation from \(.applicationName)"
            ],
            shortTitle: "Recommend Book",
            systemImageName: "book.closed.fill"
        )
        AppShortcut(
            intent: GetWeatherIntent(),
            phrases: [
                "Get the weather in \(.applicationName)",
                "Check weather with \(.applicationName)"
            ],
            shortTitle: "Get Weather",
            systemImageName: "cloud.sun.fill"
        )
        AppShortcut(
            intent: SearchWebIntent(),
            phrases: [
                "Search the web in \(.applicationName)",
                "Look something up with \(.applicationName)"
            ],
            shortTitle: "Search Web",
            systemImageName: "magnifyingglass"
        )
        AppShortcut(
            intent: OpenChatIntent(),
            phrases: [
                "Open \(.applicationName) chat",
                "Start chatting in \(.applicationName)",
                "Open chat in \(.applicationName)"
            ],
            shortTitle: "Open Chat",
            systemImageName: "message.fill"
        )
        AppShortcut(
            intent: OpenExampleIntent(),
            phrases: [
                "Open \(\.$example) in \(.applicationName)",
                "Show \(\.$example) in \(.applicationName)"
            ],
            shortTitle: "Open Example",
            systemImageName: "sparkles"
        )
        AppShortcut(
            intent: OpenToolIntent(),
            phrases: [
                "Open \(\.$tool) tool in \(.applicationName)",
                "Show \(\.$tool) in \(.applicationName)"
            ],
            shortTitle: "Open Tool",
            systemImageName: "wrench.and.screwdriver"
        )
        AppShortcut(
            intent: OpenSchemaIntent(),
            phrases: [
                "Open \(\.$schema) in \(.applicationName)",
                "Show \(\.$schema) in \(.applicationName)"
            ],
            shortTitle: "Open Schema",
            systemImageName: "doc.text"
        )
        AppShortcut(
            intent: OpenLanguageIntent(),
            phrases: [
                "Open \(\.$language) in \(.applicationName)",
                "Show \(\.$language) in \(.applicationName)"
            ],
            shortTitle: "Open Language",
            systemImageName: "globe"
        )
    }
}
