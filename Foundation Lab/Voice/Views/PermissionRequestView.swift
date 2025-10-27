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
    let permissionManager: PermissionManager
    @State private var isRequestingPermissions = false

    init(permissionManager: PermissionManager) {
        self.permissionManager = permissionManager
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform")
                .padding()
                .font(.system(size: 60))
                .padding(.vertical)
                .foregroundStyle(.indigo.gradient)
                .background {
                    Circle()
                        .fill(.regularMaterial)
                        .frame(width: 120, height: 120)
                }

            VStack(spacing: 0) {
                Text("Welcome to Voice")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 4)

                Text("Voice-powered reminders")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom)
            }

            // Permission items
            VStack(spacing: 20) {
                PermissionItemView(
                    icon: "mic.fill",
                    title: "Microphone",
                    description: "To hear your voice",
                    status: getMicrophonePermissionStatus()
                )

                PermissionItemView(
                    icon: "waveform",
                    title: "Speech Recognition",
                    description: "To understand your words",
                    status: getSpeechPermissionStatus()
                )

                PermissionItemView(
                    icon: "checklist",
                    title: "Reminders",
                    description: "To save your reminders",
                    status: getRemindersPermissionStatus()
                )
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

            Button(action: requestPermissions) {
                HStack {
                    if isRequestingPermissions {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text(permissionManager.allPermissionsGranted ? "Continue" : "Grant Permissions")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonBorderShape(.roundedRectangle(radius: 12))
            .disabled(isRequestingPermissions)
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
            .padding(.vertical)
        }
        .padding()
        .alert("Permissions Required",
               isPresented: .init(
                   get: { permissionManager.showPermissionAlert },
                   set: { _ in }
               )) {
            Button("Open Settings", action: permissionManager.openSettings)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(permissionManager.permissionAlertMessage)
        }
        .frame(maxHeight: .infinity)
    }

    func requestPermissions() {
        // If all permissions are already granted, just update the status
        if permissionManager.allPermissionsGranted {
            // Force a re-check to ensure the parent view updates
            permissionManager.checkAllPermissions()
            return
        }

        isRequestingPermissions = true

        Task {
            _ = await permissionManager.requestAllPermissions()
            isRequestingPermissions = false

            if !permissionManager.allPermissionsGranted {
                permissionManager.showSettingsAlert()
            }
        }
    }

    // MARK: - Permission Status Helpers

    private func getMicrophonePermissionStatus() -> PermissionItemView.PermissionStatus {
#if os(iOS)
        return permissionManager.microphonePermissionStatus == .granted ? .granted : .pending
#else
        return permissionManager.microphonePermissionStatus == .granted ? .granted : .pending
#endif
    }

    private func getSpeechPermissionStatus() -> PermissionItemView.PermissionStatus {
        return permissionManager.speechPermissionStatus == .authorized ? .granted : .pending
    }

    private func getRemindersPermissionStatus() -> PermissionItemView.PermissionStatus {
        return permissionManager.hasRemindersAccess ? .granted : .pending
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
                .font(.system(size: 20))
                .foregroundStyle(status == .granted ? Color.indigo : Color.gray)

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
                    .foregroundStyle(Color.indigo.gradient)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

#Preview {
    PermissionRequestView(permissionManager: PermissionManager())
}