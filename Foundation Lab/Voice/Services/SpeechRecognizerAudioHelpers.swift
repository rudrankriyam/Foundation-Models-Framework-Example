//
//  SpeechRecognizerAudioHelpers.swift
//  Foundation Lab
//
//  Created by Rudrank Riyam on 10/27/25.
//

import Foundation
import Speech
import AVFoundation
import Accelerate
import OSLog

extension SpeechRecognizer {
    func configureAudioSessionIfNeeded() throws {
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

    func prepareAudioEngine() throws {
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

    func determineTapFormat(for inputNode: AVAudioInputNode) throws -> AVAudioFormat {
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

    func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
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

    func smoothAmplitude(_ newAmplitude: Double) -> Double {
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

    func prepareRecognitionRequest() -> SFSpeechAudioBufferRecognitionRequest {
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

    func configureRecognitionTask(with request: SFSpeechAudioBufferRecognitionRequest) {
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

    func handleRecognitionError(_ error: Error) {
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

    func processRecognitionResult(_ result: SFSpeechRecognitionResult) {
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
}
