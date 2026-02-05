//
//  PermissionRequestView.swift
//  Foundation Lab
//
//  Created by Rudrank Riyam on 10/27/25.
//

import SwiftUI
import AVFoundation
import Speech
import EventKit

struct PermissionRequestView: View {
    let viewModel: VoiceViewModel
    @State private var isRequestingPermissions = false

    init(viewModel: VoiceViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            // Permission items
            VStack(spacing: 20) {
                PermissionItemView(
                    icon: "mic.fill",
                    title: String(localized: "Microphone"),
                    description: String(localized: "To hear your voice"),
                    status: getMicrophonePermissionStatus()
                )

                PermissionItemView(
                    icon: "waveform",
                    title: String(localized: "Speech Recognition"),
                    description: String(localized: "To understand your words"),
                    status: getSpeechPermissionStatus()
                )
            }
            .padding()

            Button(action: requestPermissions) {
                HStack {
                    if isRequestingPermissions {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text(viewModel.allPermissionsGranted ?
                             String(localized: "Continue") :
                             String(localized: "Grant Permissions"))
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonBorderShape(.roundedRectangle(radius: 12))
            .disabled(isRequestingPermissions)
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .padding(.vertical)
        }
        .padding()
        .alert(String(localized: "Permissions Required"),
               isPresented: .init(
                   get: { viewModel.showPermissionAlert },
                   set: { _ in viewModel.showPermissionAlert = false }
               )) {
            Button("Open Settings", action: viewModel.openSettings)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(viewModel.permissionAlertMessage)
        }
        .frame(maxHeight: .infinity)
    }

    func requestPermissions() {
        // If all permissions are already granted, just update the status
        if viewModel.allPermissionsGranted {
            // Force a re-check to ensure the parent view updates
            viewModel.checkAllPermissions()
            return
        }

        isRequestingPermissions = true

        Task {
            _ = await viewModel.requestAllPermissions()
            isRequestingPermissions = false

            if !viewModel.allPermissionsGranted {
                viewModel.showSettingsAlert()
            }
        }
    }

    // MARK: - Permission Status Helpers

    private func getMicrophonePermissionStatus() -> PermissionItemView.PermissionStatus {
#if os(iOS)
        return viewModel.microphonePermissionStatus == .granted ? .granted : .pending
#else
        return viewModel.microphonePermissionStatus == .granted ? .granted : .pending
#endif
    }

    private func getSpeechPermissionStatus() -> PermissionItemView.PermissionStatus {
        viewModel.speechPermissionStatus == .authorized ? .granted : .pending
    }
}

struct PermissionItemView: View {
    let icon: String
    let title: String
    let description: String
    let status: PermissionStatus

    enum PermissionStatus {
        case pending, granted
    }

    var body: some View {
        return HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(status == .granted ? Color.blue : Color.gray)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if status == .granted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.blue.gradient)
                    .transition(.scale.combined(with: .opacity))
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(status == .granted ? "Granted" : "Not granted")
    }
}

#Preview {
    PermissionRequestView(viewModel: VoiceViewModel())
}
