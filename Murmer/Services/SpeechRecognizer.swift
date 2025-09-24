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
import Accelerate

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
class SpeechRecognizer: NSObject, ObservableObject, SpeechRecognitionService {
    @Published var state: SpeechRecognitionState = .idle
    @Published var hasPermission = false
    @Published var currentAmplitude: Double = 0
    @Published var isRecording = false

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var audioBufferCount = 0

    // Simple flag to prevent double processing
    private var hasProcessedFinalResult = false
    
    // Amplitude monitoring parameters
    private var amplitudeHistory: [Double] = []
    private let historySize = 10
    private let smoothingFactor = 0.8
    
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

        // Cancel any ongoing recognition first, but only if we're currently listening
        if case .listening = state {
            print("🚀 Currently listening, calling stopRecognition() to clean up")
            stopRecognition()
        } else {
            print("🚀 Not currently listening, skipping cleanup")
        }

        print("🚀 Configuring audio session for speech recognition")

        // Configure audio session first with retry logic
        #if os(iOS)
        var attempts = 0
        let maxAttempts = 3

        while attempts < maxAttempts {
            do {
                // Small delay on retry to allow previous session to fully deactivate
                if attempts > 0 {
                    Thread.sleep(forTimeInterval: 0.2) // 200ms
                    print("🚀 Retrying audio session configuration (attempt \(attempts + 1))")
                }

                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                print("🚀 Audio session configured successfully")
                break // Success, exit the retry loop

            } catch {
                attempts += 1
                print("🚀 Audio session configuration failed (attempt \(attempts)): \(error.localizedDescription)")

                if attempts >= maxAttempts {
                    let recognitionError = SpeechRecognitionError.audioSessionFailed
                    state = .error(recognitionError)
                    throw recognitionError
                }
            }
        }
        #endif

        // Create and configure recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

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
                    if let error = error {
                        print("🎤 CALLBACK IGNORED: Error - \(error.localizedDescription)")
                    } else if let result = result {
                        print("🎤 CALLBACK IGNORED: Result - isFinal=\(result.isFinal), text='\(result.bestTranscription.formattedString)'")
                    } else {
                        print("🎤 CALLBACK IGNORED: Unknown callback")
                    }
                    return
                }

                if let error = error {
                    print("🔴 SPEECH ERROR: \(error.localizedDescription)")

                    // If we have partial text already captured, don't treat this as an error
                    // This can happen when recognition is cancelled but we already got speech
                    if case .listening(let partialText) = self.state, !partialText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        print("🔄 Ignoring error since we have partial text: '\(partialText)'")
                        self.hasProcessedFinalResult = true
                        self.state = .completed(finalText: partialText)
                    } else {
                        self.hasProcessedFinalResult = true
                        self.state = .error(.recognitionFailed(error.localizedDescription))
                    }
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

        // Reset audio engine to ensure it picks up the new audio session configuration
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.reset()

        // Configure audio input with proper format
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        print("🎤 Hardware format after session config: sampleRate=\(recordingFormat.sampleRate), channels=\(recordingFormat.channelCount)")

        // Remove any existing tap before installing new one
        if inputNode.numberOfInputs > 0 {
            inputNode.removeTap(onBus: 0)
        }

        // Use nil format to let AVAudioEngine handle format conversion automatically
        let validFormat: AVAudioFormat? = nil
        print("🎤 Using automatic format conversion (nil format)")

        // If we still need a specific format, use the recording format or fallback
        let tapFormat: AVAudioFormat
        if recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 {
            tapFormat = recordingFormat
            print("🎤 Installing tap with hardware format")
        } else {
            guard let fallbackFormat = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1) else {
                let error = SpeechRecognitionError.audioSessionFailed
                state = .error(error)
                throw error
            }
            tapFormat = fallbackFormat
            print("🎤 Installing tap with fallback format: sampleRate=16000, channels=1")
        }

        audioBufferCount = 0
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: tapFormat) { [weak self] (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            guard let self = self, !self.hasProcessedFinalResult else { return }

            // Send buffer to speech recognition
            self.recognitionRequest?.append(buffer)

            // Process amplitude for visual feedback on main thread
            DispatchQueue.main.async {
                self.processAudioBuffer(buffer)
            }

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
        isRecording = true
        print("🚀 START RECOGNITION COMPLETED SUCCESSFULLY")
        
    }
    
    func stopRecognition() {
        print("🛑 STOP RECOGNITION CALLED")
        
        // If we're listening and have partial text, complete with that text
        if case .listening(let partialText) = state, !partialText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            print("🛑 Completing with partial text: '\(partialText)'")
            state = .completed(finalText: partialText)
        } else {
            print("🛑 No partial text to use, setting to idle")
            state = .idle
        }
        
        isRecording = false
        currentAmplitude = 0

        // Clean up resources
        cleanupRecognition()

        // Deactivate audio session to allow speech synthesis
        #if os(iOS)
        DispatchQueue.global(qos: .background).async {
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                print("🎤 Deactivated audio session after speech recognition")
            } catch {
                print("🎤 Failed to deactivate audio session: \(error.localizedDescription)")
            }
        }
        #endif
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

        // Let the system handle audio session cleanup automatically

        // Prevent further callback processing after cleanup
        hasProcessedFinalResult = true

        print("🧹 CLEANUP COMPLETED")
    }
    
    // MARK: - Amplitude Monitoring
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else {
            return
        }
        let frameLength = Int(buffer.frameLength)

        // Calculate RMS amplitude
        var rms: Float = 0
        vDSP_rmsqv(channelData, 1, &rms, vDSP_Length(frameLength))

        // Smooth the amplitude using logarithmic scale for better dynamic range
        let normalizedAmplitude = Double(min(log10(1 + rms * 9), 1.0))
        let smoothedAmplitude = smoothAmplitude(normalizedAmplitude)

        // Update amplitude on main thread
        currentAmplitude = smoothedAmplitude
    }

    private func smoothAmplitude(_ newAmplitude: Double) -> Double {
        amplitudeHistory.append(newAmplitude)
        if amplitudeHistory.count > historySize {
            amplitudeHistory.removeFirst()
        }

        // Apply exponential smoothing
        var smoothed = amplitudeHistory[0]
        for i in 1..<amplitudeHistory.count {
            smoothed = smoothed * smoothingFactor + amplitudeHistory[i] * (1 - smoothingFactor)
        }

        return smoothed
    }
}

// MARK: - SFSpeechRecognitionTaskDelegate
extension SpeechRecognizer: SFSpeechRecognitionTaskDelegate {
    nonisolated func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishRecognition recognitionResult: SFSpeechRecognitionResult) {
        print("🎯 TASK DELEGATE: Final recognition result - '\(recognitionResult.bestTranscription.formattedString)'")
    }

    nonisolated func speechRecognitionTaskFinishedReadingAudio(_ task: SFSpeechRecognitionTask) {
        print("🎯 TASK DELEGATE: Finished reading audio")
    }

    nonisolated func speechRecognitionTaskWasCancelled(_ task: SFSpeechRecognitionTask) {
        print("🎯 TASK DELEGATE: Task was cancelled")
    }

    nonisolated func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishSuccessfully successfully: Bool) {
        print("🎯 TASK DELEGATE: Task finished successfully: \(successfully)")
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
