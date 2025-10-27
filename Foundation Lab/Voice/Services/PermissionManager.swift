//
//  PermissionManager.swift
//  Foundation Lab
//
//  Created by Rudrank Riyam on 10/27/25.
//

import Foundation
import Speech
import EventKit

#if os(iOS)
import AVFoundation
import UIKit
#elseif os(macOS)
import AppKit
import AVFoundation
#endif

// MARK: - Microphone Permission Type

#if os(iOS)
typealias MicrophonePermissionStatus = AVAudioApplication.recordPermission
#else
enum MicrophonePermissionStatus {
    case undetermined
    case denied
    case granted
}
#endif

// MARK: - Permission Service Protocol

/// Protocol defining the interface for permission management
@MainActor
protocol PermissionServiceProtocol: AnyObject {
    /// Microphone permission status
    var microphonePermissionStatus: MicrophonePermissionStatus { get }

    /// Speech recognition permission status
    var speechPermissionStatus: SFSpeechRecognizerAuthorizationStatus { get }

    /// Reminders permission status
    var remindersPermissionStatus: EKAuthorizationStatus { get }

    /// Whether all required permissions are granted
    var allPermissionsGranted: Bool { get }

    /// Whether to show permission alert
    var showPermissionAlert: Bool { get }

    /// Message for permission alert
    var permissionAlertMessage: String { get }

    /// Check current status of all permissions
    func checkAllPermissions()

    /// Request all required permissions
    /// - Returns: True if all permissions granted, false otherwise
    func requestAllPermissions() async -> Bool

    /// Show settings alert for denied permissions
    func showSettingsAlert()

    /// Open system settings for permissions
    func openSettings()
}

// MARK: - Permission Manager Implementation

@MainActor
class PermissionManager: PermissionServiceProtocol {

#if os(iOS)
    var microphonePermissionStatus: AVAudioApplication.recordPermission = .undetermined {
        didSet { updateAllPermissionsStatus() }
    }
#else
    var microphonePermissionStatus: MicrophonePermissionStatus = .undetermined {
        didSet { updateAllPermissionsStatus() }
    }
#endif

    var speechPermissionStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined {
        didSet { updateAllPermissionsStatus() }
    }
    var remindersPermissionStatus: EKAuthorizationStatus = .notDetermined {
        didSet { updateAllPermissionsStatus() }
    }
    var allPermissionsGranted = false
    var showPermissionAlert = false
    var permissionAlertMessage = ""

    var hasRemindersAccess: Bool {
        isRemindersPermissionGranted(remindersPermissionStatus)
    }

    private let eventStore = EKEventStore()

    init() {
        initializeAudioSessionIfNeeded()
        checkAllPermissions()
    }

    private func initializeAudioSessionIfNeeded() {
        #if os(iOS)
        // Initialize AVAudioSession early to prevent factory registration issues
        let audioSession = AVAudioSession.sharedInstance()
        // Just access the shared instance to ensure it's initialized
        _ = audioSession
        #endif
    }

    func checkAllPermissions() {
        checkMicrophonePermission()
        checkSpeechPermission()
        checkRemindersPermission()
        updateAllPermissionsStatus()
        debugPrintPermissionStatuses(context: "Initial check")
    }

    func requestAllPermissions() async -> Bool {
        _ = await requestMicrophonePermission()

        _ = await requestSpeechPermission()
        _ = await requestRemindersPermission()

        updateAllPermissionsStatus()
        debugPrintPermissionStatuses(context: "Post-request")
        return allPermissionsGranted
    }

    // MARK: - Microphone Permission

#if os(iOS)
    private func checkMicrophonePermission() {
        let status = AVAudioApplication.shared.recordPermission
        microphonePermissionStatus = status
    }

    private func requestMicrophonePermission() async -> Bool {
        if microphonePermissionStatus == .granted {
            return true
        }

        let granted = await AVAudioApplication.requestRecordPermission()
        microphonePermissionStatus = granted ? .granted : .denied
        return granted
    }
#else
    // macOS implementations for microphone permission

    private func checkMicrophonePermission() {
        // On macOS, we can't directly check microphone permission status
        // We need to attempt access to determine the status
        // For now, keep the current status unless it's the initial state
        if microphonePermissionStatus == .undetermined {
            // Try to determine status by attempting a quick access test
            Task { @MainActor in
                _ = await self.testMicrophoneAccess()
            }
        }
    }

    private func testMicrophoneAccess() async -> Bool {
        return await withCheckedContinuation { continuation in
            let audioEngine = AVAudioEngine()
            let inputNode = audioEngine.inputNode

            // Use a safer format check
            let inputFormat = inputNode.outputFormat(forBus: 0)
            let recordingFormat: AVAudioFormat

            if inputFormat.sampleRate > 0 && inputFormat.channelCount > 0 {
                recordingFormat = inputFormat
            } else {
                guard let fallbackFormat = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1) else {
                    DispatchQueue.main.async {
                        self.microphonePermissionStatus = .denied
                        continuation.resume(returning: false)
                    }
                    return
                }
                recordingFormat = fallbackFormat
            }

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { _, _ in
                // Empty tap
            }

            do {
                try audioEngine.start()
                // Success - microphone access is granted
                audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                DispatchQueue.main.async {
                    self.microphonePermissionStatus = .granted
                    continuation.resume(returning: true)
                }
            } catch {
                // Failed - microphone access denied
                audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                DispatchQueue.main.async {
                    self.microphonePermissionStatus = .denied
                    continuation.resume(returning: false)
                }
            }
        }
    }

    private func requestMicrophonePermission() async -> Bool {

        if microphonePermissionStatus == .granted {
            return true
        }

        return await testMicrophoneAccess()
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
        if isRemindersPermissionGranted(remindersPermissionStatus) {
            return true
        }

        do {
            let granted = try await eventStore.requestFullAccessToReminders()
            remindersPermissionStatus = granted ? .fullAccess : .denied
            return granted
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

        let speechGranted = speechPermissionStatus == .authorized
        let remindersGranted = isRemindersPermissionGranted(remindersPermissionStatus)

        allPermissionsGranted = micGranted && speechGranted && remindersGranted
    }

    private func isRemindersPermissionGranted(_ status: EKAuthorizationStatus) -> Bool {
        return status == .fullAccess || status == .writeOnly
    }

    func showSettingsAlert() {
        var deniedPermissions: [String] = []

        if microphonePermissionStatus == .denied {
            deniedPermissions.append("Microphone")
        }

        if speechPermissionStatus == .denied || speechPermissionStatus == .restricted {
            deniedPermissions.append("Speech Recognition")
        }
        if remindersPermissionStatus == .denied || remindersPermissionStatus == .restricted {
            deniedPermissions.append("Reminders")
        }

        if !deniedPermissions.isEmpty {
            let permissionsList = deniedPermissions.joined(separator: ", ")
            permissionAlertMessage = "Please enable \(permissionsList) in Settings to use Voice features."
            showPermissionAlert = true
        }
    }

    private func debugPrintPermissionStatuses(context: String) {
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
