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
    @ObservedObject var permissionManager: PermissionManager
    @State private var isRequestingPermissions = false
    
    var body: some View {
        VStack(spacing: 30) {
            // App icon placeholder
            ZStack {
                Circle()
                    .fill(Color.purple)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.white)
            }
            .shadow(radius: 20)
            
            // Title
            Text("Welcome to Murmer")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Voice-powered reminders, beautifully simple")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            // Permission items
            VStack(spacing: 20) {
                PermissionItemView(
                    icon: "mic.fill",
                    title: "Microphone",
                    description: "To hear your voice",
                    status: permissionManager.microphonePermissionStatus == .granted ? .granted : .pending
                )
                
                PermissionItemView(
                    icon: "waveform",
                    title: "Speech Recognition",
                    description: "To understand your words",
                    status: permissionManager.speechPermissionStatus == .authorized ? .granted : .pending
                )
                
                PermissionItemView(
                    icon: "checklist",
                    title: "Reminders",
                    description: "To save your reminders",
                    status: permissionManager.remindersPermissionStatus == .fullAccess ? .granted : .pending
                )
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.regularMaterial)
            }
            
            Spacer()
            
            // Action button
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
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.purple)
                )
                .foregroundColor(.white)
            }
            .disabled(isRequestingPermissions)
        }
        .padding()
        .alert("Permissions Required", 
               isPresented: $permissionManager.showPermissionAlert) {
            Button("Open Settings", action: permissionManager.openSettings)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(permissionManager.permissionAlertMessage)
        }
    }
    
    private func requestPermissions() {
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
        HStack(spacing: 15) {
            // Icon
            ZStack {
                Circle()
                    .fill(status == .granted ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(status == .granted ? Color.green : Color.gray)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Status
            if status == .granted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
}
