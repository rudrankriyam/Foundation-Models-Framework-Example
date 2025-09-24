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

        // Check current authorization status instead of cached value
        let authStatus = SFSpeechRecognizer.authorizationStatus()

        guard authStatus == .authorized else {
            hasPermission = false
            let error = SpeechRecognitionError.notAuthorized
            state = .error(error)
            throw error
        }

        hasPermission = true

        let isAvailable = speechRecognizer?.isAvailable ?? false

        guard isAvailable else {
            let error = SpeechRecognitionError.recognizerNotAvailable
            state = .error(error)
            throw error
        }
        
        // Cancel any ongoing recognition
        stopRecognition()
        
#if os(iOS)
        // Configure audio session - available only on iOS
        let audioSession = AVAudioSession.sharedInstance()

        do {
            // Use voice recognition mode for better speech recognition performance
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
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
        
        // Configure request
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false
        
        if #available(iOS 16.0, *) {
            recognitionRequest.addsPunctuation = true
        }
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else {
                return
            }

            Task { @MainActor in
                if let error = error {
                    // Check if this is a cancellation error (user tapped to stop)
                    if error.localizedDescription.contains("cancelled") ||
                       error.localizedDescription.contains("Cancelled") ||
                       error.localizedDescription.contains("canceled") ||
                       error.localizedDescription.contains("Canceled") {
                        print("Speech recognition cancelled by user")
                        self.state = .idle  // Don't treat cancellation as error
                    } else {
                        print("Speech recognition error: \(error.localizedDescription)")
                        self.state = .error(.recognitionFailed(error.localizedDescription))
                    }
                    self.stopRecognition()
                    return
                }

                if let result = result {
                    let transcription = result.bestTranscription.formattedString

                    if result.isFinal {
                        self.state = .completed(finalText: transcription)
                        self.stopRecognition()
                    } else {
                        self.state = .listening(partialText: transcription)
                    }
                }
            }
        }
        
        
        // Configure audio input with proper format
        let inputFormat = inputNode.outputFormat(forBus: 0)

        // Create a proper recording format if input format is invalid
        let recordingFormat: AVAudioFormat
        if inputFormat.sampleRate > 0 && inputFormat.channelCount > 0 {
            recordingFormat = inputFormat
        } else {
            // Fallback to a standard format
            guard let fallbackFormat = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1) else {
                let error = SpeechRecognitionError.audioSessionFailed
                state = .error(error)
                throw error
            }
            recordingFormat = fallbackFormat
        }


        audioBufferCount = 0
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)

            // Log every 50th buffer to avoid spam
            if let self = self {
                self.audioBufferCount += 1
                if self.audioBufferCount % 50 == 0 {
                }
            }
        }
        
        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            let recognitionError = SpeechRecognitionError.audioSessionFailed
            state = .error(recognitionError)
            throw recognitionError
        }

        // Update state to listening
        state = .listening()
        
        
    }
    
    func stopRecognition() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        if recognitionRequest != nil {
            recognitionRequest?.endAudio()
        }

        if recognitionTask != nil {
            recognitionTask?.cancel()
        }

        recognitionTask = nil
        recognitionRequest = nil

        // Only set to idle if we're not already showing a completed state or error
        if case .listening = state {
            state = .idle
        }
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
