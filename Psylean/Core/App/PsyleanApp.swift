//
//  PsyleanApp.swift
//  Psylean
//
//  Created by Rudrank Riyam on 6/26/25.
//

import SwiftUI
import AppIntents

@main
struct PsyleanApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    PsyleanAppShortcuts.updateAppShortcutParameters()
                }
        }
    }
}
