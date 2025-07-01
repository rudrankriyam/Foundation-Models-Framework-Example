//
//  FoundationLabApp.swift
//  Foundation Lab
//
//  Created by Rudrank Riyam on 6/9/25.
//

import SwiftUI
import AppIntents
import FoundationModels

@main
struct FoundationLabApp: App {
  @State private var isModelAvailable = true
  @State private var unavailabilityReason: SystemLanguageModel.Availability.UnavailableReason?
  
  var body: some Scene {
    WindowGroup {
      AdaptiveNavigationView()
#if os(macOS)
        .frame(minWidth: 800, minHeight: 600)
#endif
        .onAppear {
          FoundationLabAppShortcuts.updateAppShortcutParameters()
          checkModelAvailability()
        }
        .tint(.main)
        .sheet(isPresented: Binding(
          get: { !isModelAvailable },
          set: { _ in }
        )) {
          ModelUnavailableView(reason: unavailabilityReason)
            .interactiveDismissDisabled()
        }
    }
#if os(macOS)
    .defaultSize(width: 1000, height: 700)
#endif
  }
  
  private func checkModelAvailability() {
    let model = SystemLanguageModel.default
    switch model.availability {
    case .available:
      isModelAvailable = true
      // TEST: Simulate unavailable state after 2 seconds
      #if DEBUG
      DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        self.isModelAvailable = false
        self.unavailabilityReason = .appleIntelligenceNotEnabled
      }
      #endif
    case .unavailable(let reason):
      isModelAvailable = false
      unavailabilityReason = reason
    }
  }
}
