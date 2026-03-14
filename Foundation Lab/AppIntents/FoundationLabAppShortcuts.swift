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
            intent: AnalyzeNutritionIntent(),
            phrases: [
                "Analyze nutrition in \(.applicationName)",
                "Check calories with \(.applicationName)"
            ],
            shortTitle: "Analyze Nutrition",
            systemImageName: "fork.knife"
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
            intent: SearchContactsIntent(),
            phrases: [
                "Search contacts in \(.applicationName)",
                "Find someone with \(.applicationName)"
            ],
            shortTitle: "Search Contacts",
            systemImageName: "person.crop.circle"
        )
        AppShortcut(
            intent: QueryCalendarIntent(),
            phrases: [
                "Check my calendar in \(.applicationName)",
                "Ask calendar with \(.applicationName)"
            ],
            shortTitle: "Query Calendar",
            systemImageName: "calendar"
        )
        AppShortcut(
            intent: ManageRemindersIntent(),
            phrases: [
                "Manage reminders in \(.applicationName)",
                "Create a reminder with \(.applicationName)"
            ],
            shortTitle: "Manage Reminders",
            systemImageName: "checklist"
        )
        AppShortcut(
            intent: GetCurrentLocationIntent(),
            phrases: [
                "Get my location in \(.applicationName)",
                "Check location with \(.applicationName)"
            ],
            shortTitle: "Get Location",
            systemImageName: "location"
        )
        AppShortcut(
            intent: SearchMusicCatalogIntent(),
            phrases: [
                "Search music in \(.applicationName)",
                "Find music with \(.applicationName)"
            ],
            shortTitle: "Search Music",
            systemImageName: "music.note"
        )
        AppShortcut(
            intent: QueryHealthDataIntent(),
            phrases: [
                "Check health data in \(.applicationName)",
                "Ask health data with \(.applicationName)"
            ],
            shortTitle: "Query Health",
            systemImageName: "heart.text.square"
        )
    }
}
