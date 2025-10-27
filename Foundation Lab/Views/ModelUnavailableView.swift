//
//  ModelUnavailableView.swift
//  Foundation Lab
//
//  Created by Rudrank Riyam on 07/01/25.
//

import SwiftUI
import FoundationModels

struct ModelUnavailableView: View {
    let reason: SystemLanguageModel.Availability.UnavailableReason?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ContentUnavailableView {
            Label("Apple Intelligence Not Available", systemImage: "sparkles.slash")
        } description: {
            Text(descriptionText)
                .multilineTextAlignment(.center)
        } actions: {
            if showSettingsButton {
                Button("Open Settings") {
                    openSettings()
                }
                .buttonStyle(.borderedProminent)
            }

            Button("Continue Anyway") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
#if os(iOS)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
#else
        .frame(width: 500, height: 300)
#endif
    }

    private var descriptionText: String {
        guard let reason = reason else {
            return "Apple Intelligence is not available on this device."
        }

        switch reason {
        case .deviceNotEligible:
            return "This device is not eligible for Apple Intelligence. Foundation Models Framework requires an " +
                   "iPhone 15 Pro or later, iPad with A17 Pro or M1 and newer, Apple Vision Pro, " +
                   "or a Mac with Apple silicon."
        case .appleIntelligenceNotEnabled:
            return "Apple Intelligence is not enabled. Please enable Apple Intelligence in Settings to use " +
                   "Foundation Models Framework."
        case .modelNotReady:
            return "Apple Intelligence models are still downloading. Please wait for the download to complete " +
                   "and try again."
        @unknown default:
            return "Apple Intelligence is currently unavailable. Please try again later."
        }
    }

    private var showSettingsButton: Bool {
        guard let reason = reason else { return false }
        return reason == .appleIntelligenceNotEnabled
    }

    private func openSettings() {
#if os(iOS) || os(visionOS)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
#else
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.siri") {
            NSWorkspace.shared.open(url)
        }
#endif
    }
}

#Preview {
    ModelUnavailableView(reason: .deviceNotEligible)
}
