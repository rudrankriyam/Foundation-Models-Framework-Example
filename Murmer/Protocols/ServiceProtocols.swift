//
//  ServiceProtocols.swift
//  Murmer
//
//  Created by Rudrank Riyam on 9/24/25.
//

import Foundation
import Combine
import AVFoundation

// MARK: - Speech Recognition Protocols

/// Protocol defining the interface for speech recognition functionality
protocol SpeechRecognitionService: AnyObject, ObservableObject {
    /// Current recognition state
    var state: SpeechRecognitionState { get }

    /// Whether the service has microphone permission
    var hasPermission: Bool { get }

    /// Current audio amplitude for visual feedback
    var currentAmplitude: Double { get }

    /// Whether recording is currently active
    var isRecording: Bool { get }

    /// Request microphone permission for speech recognition
    /// - Returns: True if permission granted, false otherwise
    func requestPermission() async -> Bool

    /// Start speech recognition
    /// - Throws: SpeechRecognitionError if recognition cannot be started
    func startRecognition() throws

    /// Stop speech recognition and return to idle state
    func stopRecognition()
}

// MARK: - Speech Synthesis Protocols

/// Protocol defining the interface for text-to-speech functionality
protocol SpeechSynthesisService: AnyObject, ObservableObject {
    /// Whether speech synthesis is currently active
    var isSpeaking: Bool { get }

    /// Any current error state
    var error: SpeechSynthesizerError? { get }

    /// Available voices organized by language
    var voicesByLanguage: [String: [AVSpeechSynthesisVoice]] { get }

    /// All available languages
    var availableLanguages: [String] { get }

    /// Currently selected voice
    var selectedVoice: AVSpeechSynthesisVoice? { get set }

    /// Convert text to speech and speak it directly
    /// - Parameter text: The text to synthesize and speak
    /// - Throws: SpeechSynthesizerError if synthesis fails
    func synthesizeAndSpeak(text: String) async throws

    /// Generate speech audio file and return URL
    /// - Parameter text: The text to synthesize
    /// - Returns: URL to the generated audio file
    /// - Throws: SpeechSynthesizerError if synthesis fails
    func generateAudioFile(text: String) async throws -> URL
}

// MARK: - AI Inference Protocols

/// Protocol defining the interface for AI-powered text processing
protocol InferenceServiceProtocol {
    /// Process input text and return AI-generated response
    /// - Parameter text: Input text from speech recognition
    /// - Returns: Processed text response from AI
    /// - Throws: Error if processing fails
    func processText(_ text: String) async throws -> String
}

// MARK: - Permission Management Protocols

/// Protocol defining the interface for permission management
protocol PermissionServiceProtocol: AnyObject, ObservableObject {
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

    /// Open system settings
    func openSettings()
}

// MARK: - Type Aliases for Platform Compatibility

#if os(iOS)
typealias MicrophonePermissionStatus = AVAudioApplication.recordPermission
#else
enum MicrophonePermissionStatus {
    case undetermined
    case denied
    case granted
}
#endif

// MARK: - Import Requirements

import Speech
import EventKit
