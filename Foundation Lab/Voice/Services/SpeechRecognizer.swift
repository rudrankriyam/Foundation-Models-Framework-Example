//
//  SpeechRecognizer.swift
//  Foundation Lab
//
//  Created by Rudrank Riyam on 10/27/25.
//

import Foundation
import Speech
import AVFoundation
import Accelerate
import OSLog

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

    /// Register a handler for recognition state updates
    @discardableResult
    func addStateChangeHandler(_ handler: @escaping (SpeechRecognitionState) -> Void) -> UUID

    /// Remove a previously registered state change handler
    func removeStateChangeHandler(_ token: UUID)

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
    var state: SpeechRecognitionState = .idle {
        didSet { notifyStateHandlers() }
    }
    var hasPermission = false
    var currentAmplitude: Double = 0

    private let logger = VoiceLogging.recognition
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var stateHandlers: [UUID: (SpeechRecognitionState) -> Void] = [:]
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

    @discardableResult
    func addStateChangeHandler(_ handler: @escaping (SpeechRecognitionState) -> Void) -> UUID {
        let token = UUID()
        stateHandlers[token] = handler
        handler(state)
        return token
    }

    func removeStateChangeHandler(_ token: UUID) {
        stateHandlers[token] = nil
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
        logger.info("START RECOGNITION CALLED")

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
        logger.info("START RECOGNITION COMPLETED SUCCESSFULLY")
    }

    func stopRecognition() {
        logger.info("STOP RECOGNITION CALLED")

        // If we're listening and have partial text, complete with that text
        if case .listening(let partialText) = state,
           !partialText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if VoiceLogging.isVerboseEnabled {
                logger.debug("Completing with partial text: \(partialText, privacy: .public)")
            }
            state = .completed(finalText: partialText)
        } else {
            logger.debug("No partial text to use, setting to idle")
            state = .idle
        }

        currentAmplitude = 0

        // Clean up resources
        cleanupRecognition()

        // Deactivate audio session to allow speech synthesis
#if os(iOS)
        Task { @MainActor in
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                logger.debug("Deactivated audio session after speech recognition")
            } catch {
                logger.error("Failed to deactivate audio session: \(error.localizedDescription, privacy: .public)")
            }
        }
#endif
    }

    // MARK: - Private Helper Methods

    private func validateAuthorization() throws {
        let authStatus = SFSpeechRecognizer.authorizationStatus()
        logger.debug("Authorization status: \(authStatus.rawValue)")

        guard authStatus == .authorized else {
            hasPermission = false
            let error = SpeechRecognitionError.notAuthorized
            state = .error(error)
            logger.error("Authorization failed")
            throw error
        }

        hasPermission = true
    }

    private func ensureRecognizerAvailable() throws {
        let isAvailable = speechRecognizer?.isAvailable ?? false
        logger.debug("Speech recognizer available: \(isAvailable)")

        guard isAvailable else {
            let error = SpeechRecognitionError.recognizerNotAvailable
            state = .error(error)
            logger.error("Speech recognizer not available")
            throw error
        }
    }

    private func cleanUpIfCurrentlyListening() {
        guard case .listening = state else {
            logger.debug("Not currently listening, skipping cleanup")
            return
        }

        logger.debug("Currently listening, performing basic cleanup")

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
        logger.debug("Configuring audio session for speech recognition")

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
                logger.debug("Audio session configured successfully")
                lastError = nil
                break

            } catch {
                lastError = error
                logger.error("Audio session configuration failed (attempt \(attempt)): \(error.localizedDescription, privacy: .public)")

                if attempt == 1 {
                    usleep(100_000)
                }
            }
        }

        if lastError != nil {
            logger.error("Audio session configuration failed after all attempts")
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

        logger.debug("Recognition request prepared")
        return request
    }

    private func configureRecognitionTask(with request: SFSpeechAudioBufferRecognitionRequest) {
        logger.debug("Starting recognition task")
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self else {
                return
            }

            Task { @MainActor in
                guard !self.hasProcessedFinalResult else {
                    if VoiceLogging.isVerboseEnabled {
                        if let error {
                            self.logger.debug("Callback ignored (already processed) error: \(error.localizedDescription, privacy: .public)")
                        } else if let result {
                            self.logger.debug("Callback ignored (already processed) result final=\(result.isFinal)")
                        } else {
                            self.logger.debug("Callback ignored (already processed) unknown payload")
                        }
                    }
                    return
                }

                if let error {
                    self.handleRecognitionError(error)
                    return
                }

                if let result {
                    self.processRecognitionResult(result)
                }
            }
        }
    }

    private func handleRecognitionError(_ error: Error) {
        logger.error("Speech recognition error: \(error.localizedDescription, privacy: .public)")

        if case .listening(let partialText) = state,
           !partialText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if VoiceLogging.isVerboseEnabled {
                logger.debug("Ignoring error due to partial text: \(partialText, privacy: .public)")
            }
            hasProcessedFinalResult = true
            state = .completed(finalText: partialText)
        } else {
            hasProcessedFinalResult = true
            state = .error(.recognitionFailed(error.localizedDescription))
        }
    }

    private func processRecognitionResult(_ result: SFSpeechRecognitionResult) {
        let transcription = result.bestTranscription.formattedString

        if result.isFinal {
            if VoiceLogging.isVerboseEnabled {
                logger.debug("Final result: \(transcription, privacy: .public)")
            }
            hasProcessedFinalResult = true
            state = .completed(finalText: transcription)
        } else if !hasProcessedFinalResult {
            if VoiceLogging.isVerboseEnabled {
                logger.debug("Partial result: \(transcription, privacy: .public)")
            }
            state = .listening(partialText: transcription)
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

            if VoiceLogging.isVerboseEnabled {
                self.audioBufferCount += 1
                if self.audioBufferCount % 200 == 0 {
                    self.logger.debug("Processed \(self.audioBufferCount) audio buffers (frameLength=\(buffer.frameLength))")
                }
            }
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
            logger.debug("Audio engine started successfully")
        } catch {
            logger.error("Audio engine start failed: \(error.localizedDescription, privacy: .public)")
            state = .error(.audioSessionFailed)
            throw SpeechRecognitionError.audioSessionFailed
        }
    }

    private func determineTapFormat(for inputNode: AVAudioInputNode) throws -> AVAudioFormat {
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        if VoiceLogging.isVerboseEnabled {
            logger.debug("Hardware sampleRate=\(recordingFormat.sampleRate, format: .fixed(precision: 2))")
            logger.debug("Hardware channels=\(recordingFormat.channelCount)")
        }

        guard recordingFormat.sampleRate > 0, recordingFormat.channelCount > 0 else {
            guard let fallbackFormat = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1) else {
                state = .error(.audioSessionFailed)
                throw SpeechRecognitionError.audioSessionFailed
            }
            logger.debug("Installing tap with fallback sampleRate=16000 channels=1")
            return fallbackFormat
        }

        logger.debug("Installing tap with hardware format")
        return recordingFormat
    }

    private func cleanupRecognition() {
        logger.debug("CLEANUP RECOGNITION")

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

        logger.debug("CLEANUP COMPLETED")
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

    private func notifyStateHandlers() {
        for handler in stateHandlers.values {
            handler(state)
        }
    }
}

// MARK: - SFSpeechRecognitionTaskDelegate
extension SpeechRecognizer: SFSpeechRecognitionTaskDelegate {
    nonisolated func speechRecognitionTask(
        _ task: SFSpeechRecognitionTask,
        didFinishRecognition recognitionResult: SFSpeechRecognitionResult
    ) {
        guard VoiceLogging.isVerboseEnabled else { return }
        let transcript = recognitionResult.bestTranscription.formattedString
        VoiceLogging.recognition.debug("Task delegate final result: \(transcript, privacy: .public)")
    }

    nonisolated func speechRecognitionTaskFinishedReadingAudio(_ task: SFSpeechRecognitionTask) {
        guard VoiceLogging.isVerboseEnabled else { return }
        VoiceLogging.recognition.debug("Task delegate: finished reading audio")
    }

    nonisolated func speechRecognitionTaskWasCancelled(_ task: SFSpeechRecognitionTask) {
        guard VoiceLogging.isVerboseEnabled else { return }
        VoiceLogging.recognition.debug("Task delegate: task cancelled")
    }

    nonisolated func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishSuccessfully successfully: Bool) {
        guard VoiceLogging.isVerboseEnabled else { return }
        VoiceLogging.recognition.debug("Task delegate finished successfully=\(successfully)")
    }
}

// MARK: - SFSpeechRecognizerDelegate
extension SpeechRecognizer: SFSpeechRecognizerDelegate {
    nonisolated func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        Task { @MainActor in
            if !available {
                VoiceLogging.recognition.error("Speech recognizer availability changed to false")
                self.state = .error(.recognizerNotAvailable)
                self.stopRecognition()
            }
        }
    }
}
