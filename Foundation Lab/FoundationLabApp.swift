//
//  FoundationLabApp.swift
//  Foundation Lab
//
//  Created by Rudrank Riyam on 6/9/25.
//

import SwiftUI
import AppIntents

@main
struct FoundationLabApp: App {
  var body: some Scene {
    WindowGroup {
      AdaptiveNavigationView()
#if os(macOS)
        .frame(minWidth: 800, minHeight: 600)
#endif
        .onAppear {
          FoundationLabAppShortcuts.updateAppShortcutParameters()
        }
        .tint(.main)
    }
#if os(macOS)
    .defaultSize(width: 1000, height: 700)
#endif
  }
}
