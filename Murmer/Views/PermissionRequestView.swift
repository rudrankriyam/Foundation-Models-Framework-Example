//
//  PermissionRequestView.swift
//  Murmer
//
//  Created by Rudrank Riyam on 6/26/25.
//

import SwiftUI
import AVFoundation
import Speech
import EventKit

struct PermissionRequestView: View {
    @ObservedObject var permissionService: PermissionService
    @State private var isRequestingPermissions = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform")
                .padding()
                .font(.system(size: 60))
                .padding(.vertical)
                .glassEffect(.clear, in: .circle)

            VStack(spacing: 0) {
                Text("Welcome to Murmer")
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
                    status: permissionService.microphonePermissionStatus == .granted ? .granted : .pending
                )

                PermissionItemView(
                    icon: "waveform",
                    title: "Speech Recognition",
                    description: "To understand your words",
                    status: permissionService.speechPermissionStatus == .authorized ? .granted : .pending
                )

                PermissionItemView(
                    icon: "checklist",
                    title: "Reminders",
                    description: "To save your reminders",
                    status: permissionService.hasRemindersAccess ? .granted : .pending
                )
            }
            .padding()
            .glassEffect(.regular, in: .rect(cornerRadius: 12))

            Button(action: requestPermissions) {
                HStack {
                    if isRequestingPermissions {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text(permissionService.allPermissionsGranted ? "Continue" : "Grant Permissions")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonBorderShape(.roundedRectangle(radius: 12))
            .disabled(isRequestingPermissions)
            .buttonStyle(.glassProminent)
            .tint(.indigo)
            .padding(.vertical)
        }
        .padding()
        .alert("Permissions Required",
               isPresented: $permissionService.showPermissionAlert) {
            Button("Open Settings", action: permissionService.openSettings)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(permissionService.permissionAlertMessage)
        }
        .frame(maxHeight: .infinity)
        .background(SimpleTopGradientView())
    }

    func requestPermissions() {
        // If all permissions are already granted, just update the status
        if permissionService.allPermissionsGranted {
            // Force a re-check to ensure the parent view updates
            permissionService.checkAllPermissions()
            return
        }

        isRequestingPermissions = true

        Task {
            _ = await permissionService.requestAllPermissions()
            isRequestingPermissions = false

            if !permissionService.allPermissionsGranted {
                permissionService.showSettingsAlert()
            }
        }
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

// Mock PermissionService for preview
class MockPermissionService: PermissionService {
    override init() {
        super.init()
        // Set up mock permissions for preview
#if os(iOS)
        self.microphonePermissionStatus = .undetermined
#else
        self.microphonePermissionStatus = .granted
#endif
        self.speechPermissionStatus = .notDetermined
        self.remindersPermissionStatus = .notDetermined
        self.allPermissionsGranted = false
        self.showPermissionAlert = false
        self.permissionAlertMessage = ""
    }
}

#Preview {
    PermissionRequestView(permissionService: MockPermissionService())
}
