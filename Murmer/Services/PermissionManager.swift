//
//  PermissionManager.swift
//  Murmer
//
//  Created by Rudrank Riyam on 6/26/25.
//

import Foundation
import Speech
import EventKit
import Combine

#if os(iOS)
import AVFoundation
import UIKit
#elseif os(macOS)
import AppKit
#endif

@MainActor
class PermissionManager: ObservableObject {
    
    #if os(iOS)
    @Published var microphonePermissionStatus: AVAudioSession.RecordPermission = .undetermined
    #else
    /// Custom microphone permission enum for macOS placeholder
    enum MicrophonePermissionStatus {
        case notDetermined
        case denied
        case granted
    }
    @Published var microphonePermissionStatus: MicrophonePermissionStatus = .notDetermined
    #endif
    
    @Published var speechPermissionStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var remindersPermissionStatus: EKAuthorizationStatus = .notDetermined
    @Published var allPermissionsGranted = false
    @Published var showPermissionAlert = false
    @Published var permissionAlertMessage = ""
    
    private let eventStore = EKEventStore()
    
    init() {
        checkAllPermissions()
    }
    
    func checkAllPermissions() {
        #if os(iOS)
        checkMicrophonePermission()
        #endif
        
        checkSpeechPermission()
        checkRemindersPermission()
        updateAllPermissionsStatus()
    }
    
    func requestAllPermissions() async -> Bool {
        #if os(iOS)
        let micGranted = await requestMicrophonePermission()
        #else
        let micGranted = true // Assume granted or not applicable on macOS
        #endif
        
        _ = await requestSpeechPermission()
        _ = await requestRemindersPermission()
        
        updateAllPermissionsStatus()
        return allPermissionsGranted
    }
    
    // MARK: - Microphone Permission
    
    #if os(iOS)
    private func checkMicrophonePermission() {
        microphonePermissionStatus = AVAudioSession.sharedInstance().recordPermission
    }
    
    private func requestMicrophonePermission() async -> Bool {
        if microphonePermissionStatus == .granted {
            return true
        }
        
        return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                Task { @MainActor in
                    self.microphonePermissionStatus = granted ? .granted : .denied
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    #else
    // macOS stub implementations for microphone permission
    
    private func checkMicrophonePermission() {
        // No direct equivalent or always granted, placeholder implementation
        microphonePermissionStatus = .granted
    }
    
    private func requestMicrophonePermission() async -> Bool {
        // macOS does not require explicit microphone permission requesting here
        microphonePermissionStatus = .granted
        return true
    }
    #endif
    
    // MARK: - Speech Recognition Permission
    
    private func checkSpeechPermission() {
        speechPermissionStatus = SFSpeechRecognizer.authorizationStatus()
    }
    
    private func requestSpeechPermission() async -> Bool {
        if speechPermissionStatus == .authorized {
            return true
        }
        
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                Task { @MainActor in
                    self.speechPermissionStatus = status
                    continuation.resume(returning: status == .authorized)
                }
            }
        }
    }
    
    // MARK: - Reminders Permission
    
    private func checkRemindersPermission() {
        if #available(iOS 17.0, *) {
            remindersPermissionStatus = EKEventStore.authorizationStatus(for: .reminder)
        } else {
            remindersPermissionStatus = EKEventStore.authorizationStatus(for: .reminder)
        }
    }
    
    private func requestRemindersPermission() async -> Bool {
        if remindersPermissionStatus == .fullAccess {
            return true
        }
        
        do {
            if #available(iOS 17.0, *) {
                let granted = try await eventStore.requestFullAccessToReminders()
                remindersPermissionStatus = granted ? .fullAccess : .denied
                return granted
            } else {
                let granted = try await eventStore.requestAccess(to: .reminder)
                remindersPermissionStatus = granted ? .authorized : .denied
                return granted
            }
        } catch {
            remindersPermissionStatus = .denied
            return false
        }
    }
    
    // MARK: - Helpers
    
    private func updateAllPermissionsStatus() {
        #if os(iOS)
        let micGranted = microphonePermissionStatus == .granted
        #else
        let micGranted = microphonePermissionStatus == .granted
        #endif
        
        allPermissionsGranted = micGranted &&
                                speechPermissionStatus == .authorized && remindersPermissionStatus == .fullAccess
    }
    
    func showSettingsAlert() {
        var deniedPermissions: [String] = []
        
        #if os(iOS)
        if microphonePermissionStatus == .denied {
            deniedPermissions.append("Microphone")
        }
        #else
        // On macOS, microphone permission is always granted or handled differently, no alert needed
        #endif
        
        if speechPermissionStatus == .denied || speechPermissionStatus == .restricted {
            deniedPermissions.append("Speech Recognition")
        }
        if remindersPermissionStatus == .denied || remindersPermissionStatus == .restricted {
            deniedPermissions.append("Reminders")
        }
        
        if !deniedPermissions.isEmpty {
            permissionAlertMessage = "Please enable \(deniedPermissions.joined(separator: ", ")) in Settings to use Murmer."
            showPermissionAlert = true
        }
    }
    
    func openSettings() {
        #if os(iOS)
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
        #elseif os(macOS)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy") {
            NSWorkspace.shared.open(url)
        }
        #endif
    }
}
