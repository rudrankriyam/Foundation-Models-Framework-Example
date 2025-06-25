//
//  FMFAppShortcuts.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/25/25.
//

import AppIntents

struct FMFAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
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
    }
}