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
#if os(macOS)
                .frame(minWidth: 800, minHeight: 600)
#endif
        }
        #if os(macOS)
        .defaultSize(width: 1000, height: 700)
        #endif
    }
}
