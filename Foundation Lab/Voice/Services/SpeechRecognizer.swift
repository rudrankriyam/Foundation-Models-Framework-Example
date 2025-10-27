//
//  SpeechRecognizer.swift
//  Foundation Lab
//
//  Created by Rudrank Riyam on 10/27/25.
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

// MARK: - Speech Recognition Service Protocol

/// Protocol defining the interface for speech recognition functionality
@MainActor
protocol SpeechRecognitionService: AnyObject {
    /// Current recognition state
    var state: SpeechRecognitionState { get }

    /// Whether the service has microphone permission
    var hasPermission: Bool { get }

    /// Current audio amplitude for visual feedback
    var currentAmplitude: Double { get }

    /// Request microphone permission for speech recognition
    /// - Returns: True if permission granted, false otherwise
    func requestPermission() async -> Bool

    /// Start speech recognition
    /// - Throws: SpeechRecognitionError if recognition cannot be started
    func startRecognition() throws

    /// Stop speech recognition and return to idle state
    func stopRecognition()
}

@Observable
@MainActor
class SpeechRecognizer: NSObject, SpeechRecognitionService {
    var state: SpeechRecognitionState = .idle
    var hasPermission = false
    var currentAmplitude: Double = 0

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
        print("START RECOGNITION CALLED")

        try validateAuthorization()
        try ensureRecognizerAvailable()
        cleanUpIfCurrentlyListening()
        try configureAudioSessionIfNeeded()

        let request = prepareRecognitionRequest()
        recognitionRequest = request
        hasProcessedFinalResult = false

        configureRecognitionTask(with: request)
        try prepareAudioEngine()

        state = .listening()
        print("START RECOGNITION COMPLETED SUCCESSFULLY")
    }

    func stopRecognition() {
        print("STOP RECOGNITION CALLED")

        // If we're listening and have partial text, complete with that text
        if case .listening(let partialText) = state,
           !partialText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            print("Completing with partial text: '\(partialText)'")
            state = .completed(finalText: partialText)
        } else {
            print("No partial text to use, setting to idle")
            state = .idle
        }

        currentAmplitude = 0

        // Clean up resources
        cleanupRecognition()

        // Deactivate audio session to allow speech synthesis
        #if os(iOS)
        DispatchQueue.global(qos: .background).async {
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                print("Deactivated audio session after speech recognition")
            } catch {
                print("Failed to deactivate audio session")
                print("Deactivation error: \(error.localizedDescription)")
            }
        }
        #endif
    }

    // MARK: - Private Helper Methods

    private func validateAuthorization() throws {
        let authStatus = SFSpeechRecognizer.authorizationStatus()
        print("Authorization status: \(authStatus.rawValue)")

        guard authStatus == .authorized else {
            hasPermission = false
            let error = SpeechRecognitionError.notAuthorized
            state = .error(error)
            print("Authorization failed")
            throw error
        }

        hasPermission = true
    }

    private func ensureRecognizerAvailable() throws {
        let isAvailable = speechRecognizer?.isAvailable ?? false
        print("Speech recognizer available: \(isAvailable)")

        guard isAvailable else {
            let error = SpeechRecognitionError.recognizerNotAvailable
            state = .error(error)
            print("Speech recognizer not available")
            throw error
        }
    }

    private func cleanUpIfCurrentlyListening() {
        guard case .listening = state else {
            print("Not currently listening, skipping cleanup")
            return
        }

        print("Currently listening, performing basic cleanup")

        if let task = recognitionTask {
            task.cancel()
            recognitionTask = nil
        }

        if let request = recognitionRequest {
            request.endAudio()
            recognitionRequest = nil
        }

        if audioEngine.isRunning {
            audioEngine.stop()
        }

        let inputNode = audioEngine.inputNode
        if inputNode.numberOfInputs > 0 {
            inputNode.removeTap(onBus: 0)
        }

        hasProcessedFinalResult = true
        state = .idle
        currentAmplitude = 0
    }

    private func configureAudioSessionIfNeeded() throws {
        print("Configuring audio session for speech recognition")

        #if os(iOS)
        var lastError: Error?

        for attempt in 1...2 {
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(
                    .playAndRecord,
                    mode: .measurement,
                    options: [.duckOthers, .defaultToSpeaker]
                )
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                print("Audio session configured successfully")
                lastError = nil
                break

            } catch {
                lastError = error
                print("Audio session configuration failed (attempt \(attempt))")
                print("Error: \(error.localizedDescription)")

                if attempt == 1 {
                    usleep(100_000)
                }
            }
        }

        if lastError != nil {
            print("Audio session configuration failed after all attempts")
            state = .error(.audioSessionFailed)
            throw SpeechRecognitionError.audioSessionFailed
        }
        #endif
    }

    private func prepareRecognitionRequest() -> SFSpeechAudioBufferRecognitionRequest {
        let request = SFSpeechAudioBufferRecognitionRequest()

        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = false

        if #available(iOS 16.0, *) {
            request.addsPunctuation = true
        }

        if #available(iOS 13.0, *) {
            request.taskHint = .dictation
        }

        print("Recognition request prepared")
        return request
    }

    private func configureRecognitionTask(with request: SFSpeechAudioBufferRecognitionRequest) {
        print("Starting recognition task...")
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self else {
                return
            }

            Task { @MainActor in
                guard !self.hasProcessedFinalResult else {
                    if let error {
                        print("CALLBACK IGNORED: Error - \(error.localizedDescription)")
                    } else if let result {
                        print("CALLBACK IGNORED: Result - isFinal=\(result.isFinal)")
                        print("CALLBACK IGNORED TEXT: '\(result.bestTranscription.formattedString)'")
                    } else {
                        print("CALLBACK IGNORED: Unknown callback")
                    }
                    return
                }

                if let error {
                    print("SPEECH ERROR: \(error.localizedDescription)")

                    if case .listening(let partialText) = self.state,
                       !partialText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        print("Ignoring error; partial text available")
                        print("Partial text: '\(partialText)'")
                        self.hasProcessedFinalResult = true
                        self.state = .completed(finalText: partialText)
                    } else {
                        self.hasProcessedFinalResult = true
                        self.state = .error(.recognitionFailed(error.localizedDescription))
                    }
                    return
                }

                if let result {
                    let transcription = result.bestTranscription.formattedString

                    if result.isFinal {
                        print("FINAL RESULT: '\(transcription)'")
                        self.hasProcessedFinalResult = true
                        self.state = .completed(finalText: transcription)
                    } else if !self.hasProcessedFinalResult {
                        print("PARTIAL RESULT: '\(transcription)'")
                        self.state = .listening(partialText: transcription)
                    }
                }
            }
        }
    }

    private func prepareAudioEngine() throws {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.reset()

        let inputNode = audioEngine.inputNode
        let tapFormat = try determineTapFormat(for: inputNode)

        if inputNode.numberOfInputs > 0 {
            inputNode.removeTap(onBus: 0)
        }

        audioBufferCount = 0
        inputNode.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: tapFormat
        ) { [weak self] (buffer: AVAudioPCMBuffer, _: AVAudioTime) in
            guard let self, !self.hasProcessedFinalResult else { return }

            self.recognitionRequest?.append(buffer)

            DispatchQueue.main.async {
                self.processAudioBuffer(buffer)
            }

            self.audioBufferCount += 1
            if self.audioBufferCount % 50 == 0 {
                print("Buffer \(self.audioBufferCount)")
                print("Frame length: \(buffer.frameLength)")
            }
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
            print("Audio engine started successfully")
        } catch {
            print("Audio engine start failed: \(error.localizedDescription)")
            state = .error(.audioSessionFailed)
            throw SpeechRecognitionError.audioSessionFailed
        }
    }

    private func determineTapFormat(for inputNode: AVAudioInputNode) throws -> AVAudioFormat {
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        let sampleRateMessage = "Hardware sampleRate=\(recordingFormat.sampleRate)"
        let channelMessage = "Hardware channels=\(recordingFormat.channelCount)"
        print(sampleRateMessage)
        print(channelMessage)

        guard recordingFormat.sampleRate > 0, recordingFormat.channelCount > 0 else {
            guard let fallbackFormat = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1) else {
                state = .error(.audioSessionFailed)
                throw SpeechRecognitionError.audioSessionFailed
            }
            print("Installing tap with fallback sampleRate=16000")
            print("Installing tap with fallback channels=1")
            return fallbackFormat
        }

        print("Installing tap with hardware format")
        return recordingFormat
    }

    private func cleanupRecognition() {
        print("CLEANUP RECOGNITION")

        if let task = recognitionTask {
            task.cancel()
            recognitionTask = nil
        }

        if let request = recognitionRequest {
            request.endAudio()
            recognitionRequest = nil
        }

        if audioEngine.isRunning {
            audioEngine.stop()
        }

        let inputNode = audioEngine.inputNode
        if inputNode.numberOfInputs > 0 {
            inputNode.removeTap(onBus: 0)
        }

        hasProcessedFinalResult = true

        print("CLEANUP COMPLETED")
    }

    // MARK: - Amplitude Monitoring

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else {
            return
        }
        let frameLength = Int(buffer.frameLength)

        // Only process if we have valid audio data
        guard frameLength > 0 else { return }

        var rms: Float = 0
        vDSP_rmsqv(channelData, 1, &rms, vDSP_Length(frameLength))

        // Ensure we don't get NaN or invalid values
        guard !rms.isNaN && !rms.isInfinite && rms >= 0 else { return }

        let normalizedAmplitude = Double(min(log10(1 + rms * 9), 1.0))
        let smoothedAmplitude = smoothAmplitude(normalizedAmplitude)

        currentAmplitude = smoothedAmplitude
    }

    private func smoothAmplitude(_ newAmplitude: Double) -> Double {
        amplitudeHistory.append(newAmplitude)
        if amplitudeHistory.count > historySize {
            amplitudeHistory.removeFirst()
        }

        var smoothed = amplitudeHistory[0]
        for index in 1..<amplitudeHistory.count {
            smoothed = smoothed * smoothingFactor + amplitudeHistory[index] * (1 - smoothingFactor)
        }

        return smoothed
    }
}

// MARK: - SFSpeechRecognitionTaskDelegate
extension SpeechRecognizer: SFSpeechRecognitionTaskDelegate {
    nonisolated func speechRecognitionTask(
        _ task: SFSpeechRecognitionTask,
        didFinishRecognition recognitionResult: SFSpeechRecognitionResult
    ) {
        let transcript = recognitionResult.bestTranscription.formattedString
        print("TASK DELEGATE: Final recognition result received")
        print("TASK DELEGATE TEXT: '\(transcript)'")
    }

    nonisolated func speechRecognitionTaskFinishedReadingAudio(_ task: SFSpeechRecognitionTask) {
        print("TASK DELEGATE: Finished reading audio")
    }

    nonisolated func speechRecognitionTaskWasCancelled(_ task: SFSpeechRecognitionTask) {
        print("TASK DELEGATE: Task was cancelled")
    }

    nonisolated func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishSuccessfully successfully: Bool) {
        print("TASK DELEGATE: Task finished successfully: \(successfully)")
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