//
//  FMFApp.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/9/25.
//

import SwiftUI

@main
struct FMFApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
#if os(macOS)
        .frame(minWidth: 800, minHeight: 600)
#endif
    }
#if os(macOS)
    .defaultSize(width: 1000, height: 700)
#endif
  }
}
