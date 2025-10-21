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
    @State private var showModelUnavailableWarning = false
    @State private var apiKeyStore = ExaAPIKeyStore()

    var body: some Scene {
        WindowGroup {
            AdaptiveNavigationView()
#if os(macOS)
                .frame(minWidth: 800, minHeight: 600)
#endif
                .environment(apiKeyStore)
                .onAppear {
                    FoundationLabAppShortcuts.updateAppShortcutParameters()
                    checkModelAvailability()
                }
                .tint(.main)
                .sheet(isPresented: $showModelUnavailableWarning) {
                    ModelUnavailableView(reason: unavailabilityReason)
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
            showModelUnavailableWarning = false
        case .unavailable(let reason):
            isModelAvailable = false
            unavailabilityReason = reason
            showModelUnavailableWarning = true
        }
    }
}
