//
//  SpeechRecognizer.swift
//  Murmer
//
//  Created by Rudrank Riyam on 6/26/25.
//

import Foundation
import Speech
#if os(iOS)
import AVFoundation
#endif
import Combine

// MARK: - Recognition State

enum SpeechRecognitionState {
    case idle
    case listening(partialText: String = "")
    case completed(finalText: String)
    case error(SpeechRecognitionError)

    var isListening: Bool {
        if case .listening = self {
            return true
        }
        return false
    }

    var partialText: String {
        if case .listening(let text) = self {
            return text
        }
        return ""
    }

    var finalText: String {
        if case .completed(let text) = self {
            return text
        }
        return ""
    }

    var error: SpeechRecognitionError? {
        if case .error(let error) = self {
            return error
        }
        return nil
    }
}

// MARK: - Recognition Errors

enum SpeechRecognitionError: LocalizedError, Equatable {
    case notAuthorized
    case recognizerNotAvailable
    case audioSessionFailed
    case recognitionFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Speech recognition is not authorized. Please enable it in Settings."
        case .recognizerNotAvailable:
            return "Speech recognition is not available on this device."
        case .audioSessionFailed:
            return "Failed to configure audio session for speech recognition."
        case .recognitionFailed(let message):
            return "Speech recognition failed: \(message)"
        }
    }

    static func == (lhs: SpeechRecognitionError, rhs: SpeechRecognitionError) -> Bool {
        switch (lhs, rhs) {
        case (.notAuthorized, .notAuthorized):
            return true
        case (.recognizerNotAvailable, .recognizerNotAvailable):
            return true
        case (.audioSessionFailed, .audioSessionFailed):
            return true
        case (.recognitionFailed(let lhsMessage), .recognitionFailed(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

@MainActor
class SpeechRecognizer: NSObject, ObservableObject {
    @Published var state: SpeechRecognitionState = .idle
    @Published var hasPermission = false

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var audioBufferCount = 0

    // Simple flag to prevent double processing
    private var hasProcessedFinalResult = false
    
    override init() {
        super.init()
        
        speechRecognizer?.delegate = self
        
        // Check initial permission status
        let authStatus = SFSpeechRecognizer.authorizationStatus()
        hasPermission = authStatus == .authorized
    }
    
    deinit {
        
    }
    
    func requestPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { authStatus in
                switch authStatus {
                case .authorized:
                    DispatchQueue.main.async {
                        self.hasPermission = true
                        continuation.resume(returning: true)
                    }
                case .denied, .restricted:
                    DispatchQueue.main.async {
                        self.hasPermission = false
                        self.state = .error(.notAuthorized)
                        continuation.resume(returning: false)
                    }
                case .notDetermined:
                    DispatchQueue.main.async {
                        self.hasPermission = false
                        continuation.resume(returning: false)
                    }
                @unknown default:
                    DispatchQueue.main.async {
                        self.hasPermission = false
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }
    
    func startRecognition() throws {
        print("🚀 START RECOGNITION CALLED")

        // Check current authorization status instead of cached value
        let authStatus = SFSpeechRecognizer.authorizationStatus()
        print("🚀 Authorization status: \(authStatus.rawValue)")

        guard authStatus == .authorized else {
            hasPermission = false
            let error = SpeechRecognitionError.notAuthorized
            state = .error(error)
            print("🚀 Authorization failed")
            throw error
        }

        hasPermission = true

        let isAvailable = speechRecognizer?.isAvailable ?? false
        print("🚀 Speech recognizer available: \(isAvailable)")

        guard isAvailable else {
            let error = SpeechRecognitionError.recognizerNotAvailable
            state = .error(error)
            print("🚀 Speech recognizer not available")
            throw error
        }

        // Cancel any ongoing recognition first
        print("🚀 Calling stopRecognition() to clean up")
        stopRecognition()
        
        // Wait a brief moment for cleanup to complete
        Thread.sleep(forTimeInterval: 0.1)
        
#if os(iOS)
        // Configure audio session - available only on iOS
        let audioSession = AVAudioSession.sharedInstance()

        do {
            // Use a more compatible audio session configuration
            try audioSession.setCategory(.record, mode: .spokenAudio, options: [.duckOthers, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session configuration failed: \(error.localizedDescription)")
            let recognitionError = SpeechRecognitionError.audioSessionFailed
            state = .error(recognitionError)
            throw recognitionError
        }
#else
        // AVAudioSession is not available on macOS, skipping audio session configuration
#endif
        
        // Create and configure recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            let error = SpeechRecognitionError.audioSessionFailed
            state = .error(error)
            throw error
        }
        
        // Configure request with better settings
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false
        
        if #available(iOS 16.0, *) {
            recognitionRequest.addsPunctuation = true
        }
        
        // Add timeout to prevent indefinite listening
        if #available(iOS 13.0, *) {
            recognitionRequest.taskHint = .dictation
        }
        
        // Reset flag when starting new recognition
        hasProcessedFinalResult = false

        // Start recognition task
        print("🚀 Starting recognition task...")
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else {
                return
            }

            Task { @MainActor in
                // Simple guard - if we already processed a final result, ignore everything else
                guard !self.hasProcessedFinalResult else {
                    print("🎤 CALLBACK IGNORED: Already processed final result")
                    return
                }

                if let error = error {
                    print("🔴 SPEECH ERROR: \(error.localizedDescription)")
                    self.hasProcessedFinalResult = true
                    self.state = .error(.recognitionFailed(error.localizedDescription))
                    return
                }

                if let result = result {
                    let transcription = result.bestTranscription.formattedString
                    
                    if result.isFinal {
                        print("🎯 FINAL RESULT: '\(transcription)'")
                        self.hasProcessedFinalResult = true
                        self.state = .completed(finalText: transcription)
                    } else {
                        print("📝 PARTIAL RESULT: '\(transcription)'")
                        // Only update state if we haven't processed final result yet
                        if !self.hasProcessedFinalResult {
                            self.state = .listening(partialText: transcription)
                        }
                    }
                }
            }
        }
        
        // Configure audio input with proper format
        let inputFormat = inputNode.outputFormat(forBus: 0)

        // Create a proper recording format
        let recordingFormat: AVAudioFormat
        if inputFormat.sampleRate > 0 && inputFormat.channelCount > 0 {
            recordingFormat = inputFormat
        } else {
            // Fallback to a standard format optimized for speech
            guard let fallbackFormat = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1) else {
                let error = SpeechRecognitionError.audioSessionFailed
                state = .error(error)
                throw error
            }
            recordingFormat = fallbackFormat
        }

        // Remove any existing tap before installing new one
        if inputNode.numberOfInputs > 0 {
            inputNode.removeTap(onBus: 0)
        }

        audioBufferCount = 0
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            guard let self = self, !self.hasProcessedFinalResult else { return }
            self.recognitionRequest?.append(buffer)

            // Log every 50th buffer to avoid spam
            self.audioBufferCount += 1
            if self.audioBufferCount % 50 == 0 {
                print("🎤 Buffer \(self.audioBufferCount): frameLength=\(buffer.frameLength)")
            }
        }
        
        audioEngine.prepare()

        do {
            try audioEngine.start()
            print("🚀 Audio engine started successfully")
        } catch {
            print("Audio engine start failed: \(error.localizedDescription)")
            let recognitionError = SpeechRecognitionError.audioSessionFailed
            state = .error(recognitionError)
            throw recognitionError
        }

        // Update state to listening
        print("🚀 Setting state to .listening()")
        state = .listening()
        print("🚀 START RECOGNITION COMPLETED SUCCESSFULLY")
        
    }
    
    func stopRecognition() {
        print("🛑 STOP RECOGNITION CALLED")
        
        // If we're listening and have partial text, complete with that text
        if case .listening(let partialText) = state, !partialText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            print("🛑 Completing with partial text: '\(partialText)'")
            hasProcessedFinalResult = true
            state = .completed(finalText: partialText)
        } else {
            print("🛑 No partial text to use, setting to idle")
            state = .idle
        }
        
        // Clean up resources
        cleanupRecognition()
    }
    
    private func cleanupRecognition() {
        print("🧹 CLEANUP RECOGNITION")
        
        // Cancel any ongoing recognition task
        if let task = recognitionTask {
            task.cancel()
            recognitionTask = nil
        }

        // End the recognition request
        if let request = recognitionRequest {
            request.endAudio()
            recognitionRequest = nil
        }

        // Stop audio engine safely
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        
        // Remove tap safely
        let inputNode = audioEngine.inputNode
        if inputNode.numberOfInputs > 0 {
            do {
                inputNode.removeTap(onBus: 0)
            } catch {
                print("🧹 Error removing audio tap: \(error.localizedDescription)")
            }
        }

#if os(iOS)
        // Deactivate audio session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("🧹 Error deactivating audio session: \(error.localizedDescription)")
        }
#endif
        
        print("🧹 CLEANUP COMPLETED")
    }
}

// MARK: - SFSpeechRecognizerDelegate
extension SpeechRecognizer: SFSpeechRecognizerDelegate {
    nonisolated func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        Task { @MainActor in
            if !available {
                self.state = .error(.recognizerNotAvailable)
                self.stopRecognition()
            }
        }
    }
}
