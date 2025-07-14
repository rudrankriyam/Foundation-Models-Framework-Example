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

@MainActor
class SpeechRecognizer: NSObject, ObservableObject {
    @Published var recognizedText = ""
    @Published var partialText = ""
    @Published var isRecognizing = false
    @Published var hasPermission = false
    @Published var error: Error?
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var audioBufferCount = 0
    
    override init() {
        super.init()
        print("SpeechRecognizer: init() - Entering")
        
        speechRecognizer?.delegate = self
        print("SpeechRecognizer: init() - Delegate set")
        
        // Check initial permission status
        let authStatus = SFSpeechRecognizer.authorizationStatus()
        hasPermission = authStatus == .authorized
        print("SpeechRecognizer: init() - Initial authorization status: \(authStatus.rawValue), hasPermission: \(hasPermission)")
        print("SpeechRecognizer: init() - Exiting")
    }
    
    deinit {
        print("SpeechRecognizer: deinit - Entering")
        print("SpeechRecognizer: deinit - Current state:")
        print("  - audioEngine.isRunning: \(audioEngine.isRunning)")
        print("  - recognitionTask exists: \(recognitionTask != nil)")
        print("  - recognitionRequest exists: \(recognitionRequest != nil)")
        
        print("SpeechRecognizer: deinit - Exiting")
    }
    
    func requestPermission() async -> Bool {
        print("SpeechRecognizer: requestPermission() - Entering")
        
        return await withCheckedContinuation { continuation in
            print("SpeechRecognizer: requestPermission() - Requesting authorization")
            
            SFSpeechRecognizer.requestAuthorization { authStatus in
                print("SpeechRecognizer: requestPermission() - Authorization callback received with status: \(authStatus.rawValue)")
                
                Task { @MainActor in
                    let previousPermission = self.hasPermission
                    
                    switch authStatus {
                    case .authorized:
                        print("SpeechRecognizer: requestPermission() - Status: AUTHORIZED")
                        self.hasPermission = true
                        print("SpeechRecognizer: requestPermission() - State change: hasPermission \(previousPermission) -> \(self.hasPermission)")
                        continuation.resume(returning: true)
                    case .denied:
                        print("SpeechRecognizer: requestPermission() - Status: DENIED")
                        self.hasPermission = false
                        self.error = SpeechRecognizerError.notAuthorized
                        print("SpeechRecognizer: requestPermission() - State change: hasPermission \(previousPermission) -> \(self.hasPermission)")
                        print("SpeechRecognizer: requestPermission() - Error set: \(self.error?.localizedDescription ?? "nil")")
                        continuation.resume(returning: false)
                    case .restricted:
                        print("SpeechRecognizer: requestPermission() - Status: RESTRICTED")
                        self.hasPermission = false
                        self.error = SpeechRecognizerError.notAuthorized
                        print("SpeechRecognizer: requestPermission() - State change: hasPermission \(previousPermission) -> \(self.hasPermission)")
                        print("SpeechRecognizer: requestPermission() - Error set: \(self.error?.localizedDescription ?? "nil")")
                        continuation.resume(returning: false)
                    case .notDetermined:
                        print("SpeechRecognizer: requestPermission() - Status: NOT DETERMINED")
                        self.hasPermission = false
                        print("SpeechRecognizer: requestPermission() - State change: hasPermission \(previousPermission) -> \(self.hasPermission)")
                        continuation.resume(returning: false)
                    @unknown default:
                        print("SpeechRecognizer: requestPermission() - Status: UNKNOWN (\(authStatus.rawValue))")
                        self.hasPermission = false
                        print("SpeechRecognizer: requestPermission() - State change: hasPermission \(previousPermission) -> \(self.hasPermission)")
                        continuation.resume(returning: false)
                    }
                    
                    print("SpeechRecognizer: requestPermission() - Exiting with result: \(self.hasPermission)")
                }
            }
        }
    }
    
    func startRecognition() throws {
        print("SpeechRecognizer: startRecognition() - Entering")
        
        // Check current authorization status instead of cached value
        let authStatus = SFSpeechRecognizer.authorizationStatus()
        print("SpeechRecognizer: startRecognition() - Current authorization status: \(authStatus.rawValue)")
        
        guard authStatus == .authorized else {
            print("SpeechRecognizer: startRecognition() - ERROR: Not authorized")
            let previousPermission = hasPermission
            hasPermission = false
            print("SpeechRecognizer: startRecognition() - State change: hasPermission \(previousPermission) -> \(hasPermission)")
            throw SpeechRecognizerError.notAuthorized
        }
        
        let previousPermission = hasPermission
        hasPermission = true
        print("SpeechRecognizer: startRecognition() - State change: hasPermission \(previousPermission) -> \(hasPermission)")
        
        let isAvailable = speechRecognizer?.isAvailable ?? false
        print("SpeechRecognizer: startRecognition() - Speech recognizer available: \(isAvailable)")
        
        guard isAvailable else {
            print("SpeechRecognizer: startRecognition() - ERROR: Speech recognizer not available")
            throw SpeechRecognizerError.recognizerNotAvailable
        }
        
        // Cancel any ongoing recognition
        print("SpeechRecognizer: startRecognition() - Stopping any ongoing recognition")
        stopRecognition()
        
        #if os(iOS)
        // Configure audio session - available only on iOS
        print("SpeechRecognizer: startRecognition() - Configuring audio session")
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            print("SpeechRecognizer: startRecognition() - Audio session category set successfully")
        } catch {
            print("SpeechRecognizer: startRecognition() - ERROR: Failed to set audio session category: \(error)")
            throw error
        }
        
        do {
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("SpeechRecognizer: startRecognition() - Audio session activated successfully")
        } catch {
            print("SpeechRecognizer: startRecognition() - ERROR: Failed to activate audio session: \(error)")
            throw error
        }
        #else
        // AVAudioSession is not available on macOS, skipping audio session configuration
        print("SpeechRecognizer: startRecognition() - Skipping audio session configuration (not available on this platform)")
        #endif
        
        // Create and configure recognition request
        print("SpeechRecognizer: startRecognition() - Creating recognition request")
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        print("SpeechRecognizer: startRecognition() - Got audio engine input node")
        
        guard let recognitionRequest = recognitionRequest else {
            print("SpeechRecognizer: startRecognition() - ERROR: Recognition request is nil")
            throw SpeechRecognizerError.nilRecognitionRequest
        }
        
        // Configure request
        print("SpeechRecognizer: startRecognition() - Configuring recognition request")
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false
        
        if #available(iOS 16.0, *) {
            recognitionRequest.addsPunctuation = true
            print("SpeechRecognizer: startRecognition() - Punctuation enabled (iOS 16+)")
        }
        
        // Start recognition task
        print("SpeechRecognizer: startRecognition() - Creating recognition task")
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else {
                print("SpeechRecognizer: recognitionTask callback - Self is nil, returning")
                return
            }
            
            print("SpeechRecognizer: recognitionTask callback - Received callback")
            
            var isFinal = false
            
            if let result = result {
                print("SpeechRecognizer: recognitionTask callback - Got result")
                print("SpeechRecognizer: recognitionTask callback - Transcription: '\(result.bestTranscription.formattedString)'")
                print("SpeechRecognizer: recognitionTask callback - Is final: \(result.isFinal)")
                
                Task { @MainActor in
                    let previousPartialText = self.partialText
                    self.partialText = result.bestTranscription.formattedString
                    print("SpeechRecognizer: recognitionTask callback - State change: partialText '\(previousPartialText)' -> '\(self.partialText)'")
                    
                    isFinal = result.isFinal
                    
                    if isFinal {
                        let previousRecognizedText = self.recognizedText
                        self.recognizedText = result.bestTranscription.formattedString
                        print("SpeechRecognizer: recognitionTask callback - State change: recognizedText '\(previousRecognizedText)' -> '\(self.recognizedText)'")
                        print("SpeechRecognizer: recognitionTask callback - Recognition completed with final text")
                    }
                }
            }
            
            if let error = error {
                print("SpeechRecognizer: recognitionTask callback - ERROR: \(error)")
                print("SpeechRecognizer: recognitionTask callback - Error domain: \((error as NSError).domain)")
                print("SpeechRecognizer: recognitionTask callback - Error code: \((error as NSError).code)")
            }
            
            if error != nil || isFinal {
                print("SpeechRecognizer: recognitionTask callback - Stopping recognition (error: \(error != nil), isFinal: \(isFinal))")
                
                print("SpeechRecognizer: recognitionTask callback - Stopping audio engine")
                self.audioEngine.stop()
                
                print("SpeechRecognizer: recognitionTask callback - Removing input node tap")
                inputNode.removeTap(onBus: 0)
                
                print("SpeechRecognizer: recognitionTask callback - Cleaning up recognition request and task")
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                Task { @MainActor in
                    let previousIsRecognizing = self.isRecognizing
                    self.isRecognizing = false
                    print("SpeechRecognizer: recognitionTask callback - State change: isRecognizing \(previousIsRecognizing) -> \(self.isRecognizing)")
                    
                    if let error = error {
                        self.error = error
                        print("SpeechRecognizer: recognitionTask callback - Error set: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        print("SpeechRecognizer: startRecognition() - Recognition task created: \(recognitionTask != nil)")
        
        // Configure audio input
        print("SpeechRecognizer: startRecognition() - Configuring audio input")
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        print("SpeechRecognizer: startRecognition() - Recording format: \(recordingFormat)")
        
        audioBufferCount = 0
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            recognitionRequest.append(buffer)
            
            // Log every 50th buffer to avoid spam
            if let self = self {
                self.audioBufferCount += 1
                if self.audioBufferCount % 50 == 0 {
                    print("SpeechRecognizer: audio tap - Audio buffer count: \(self.audioBufferCount)")
                }
            }
        }
        print("SpeechRecognizer: startRecognition() - Audio tap installed")
        
        print("SpeechRecognizer: startRecognition() - Preparing audio engine")
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            print("SpeechRecognizer: startRecognition() - Audio engine started successfully")
            print("SpeechRecognizer: startRecognition() - Audio engine is running: \(audioEngine.isRunning)")
        } catch {
            print("SpeechRecognizer: startRecognition() - ERROR: Failed to start audio engine: \(error)")
            throw error
        }
        
        // Update state
        let previousIsRecognizing = isRecognizing
        let previousPartialText = partialText
        let previousRecognizedText = recognizedText
        let previousError = error
        
        isRecognizing = true
        partialText = ""
        recognizedText = ""
        error = nil
        
        print("SpeechRecognizer: startRecognition() - State changes:")
        print("  - isRecognizing: \(previousIsRecognizing) -> \(isRecognizing)")
        print("  - partialText: '\(previousPartialText)' -> '\(partialText)'")
        print("  - recognizedText: '\(previousRecognizedText)' -> '\(recognizedText)'")
        print("  - error: \(previousError?.localizedDescription ?? "nil") -> nil")
        
        print("SpeechRecognizer: startRecognition() - Exiting successfully")
    }
    
    func stopRecognition() {
        print("SpeechRecognizer: stopRecognition() - Entering")
        
        print("SpeechRecognizer: stopRecognition() - Current state:")
        print("  - isRecognizing: \(isRecognizing)")
        print("  - audioEngine.isRunning: \(audioEngine.isRunning)")
        print("  - recognitionTask exists: \(recognitionTask != nil)")
        print("  - recognitionRequest exists: \(recognitionRequest != nil)")
        
        print("SpeechRecognizer: stopRecognition() - Stopping audio engine")
        audioEngine.stop()
        print("SpeechRecognizer: stopRecognition() - Audio engine stopped, isRunning: \(audioEngine.isRunning)")
        
        print("SpeechRecognizer: stopRecognition() - Removing audio tap from input node")
        audioEngine.inputNode.removeTap(onBus: 0)
        
        if recognitionRequest != nil {
            print("SpeechRecognizer: stopRecognition() - Ending audio on recognition request")
            recognitionRequest?.endAudio()
        }
        
        if recognitionTask != nil {
            print("SpeechRecognizer: stopRecognition() - Cancelling recognition task")
            recognitionTask?.cancel()
        }
        
        print("SpeechRecognizer: stopRecognition() - Cleaning up recognition task and request")
        recognitionTask = nil
        recognitionRequest = nil
        
        let previousIsRecognizing = isRecognizing
        isRecognizing = false
        print("SpeechRecognizer: stopRecognition() - State change: isRecognizing \(previousIsRecognizing) -> \(isRecognizing)")
        
        print("SpeechRecognizer: stopRecognition() - Exiting")
    }
}

// MARK: - SFSpeechRecognizerDelegate
extension SpeechRecognizer: SFSpeechRecognizerDelegate {
    nonisolated func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        print("SpeechRecognizer: delegate availabilityDidChange - Called with available: \(available)")
        
        Task { @MainActor in
            print("SpeechRecognizer: delegate availabilityDidChange - Main actor task executing")
            
            if !available {
                print("SpeechRecognizer: delegate availabilityDidChange - Speech recognizer became unavailable")
                self.error = SpeechRecognizerError.recognizerNotAvailable
                print("SpeechRecognizer: delegate availabilityDidChange - Error set: \(self.error?.localizedDescription ?? "nil")")
                print("SpeechRecognizer: delegate availabilityDidChange - Stopping recognition due to unavailability")
                self.stopRecognition()
            } else {
                print("SpeechRecognizer: delegate availabilityDidChange - Speech recognizer is available")
            }
        }
    }
}

// MARK: - Error Types
enum SpeechRecognizerError: LocalizedError {
    case notAuthorized
    case recognizerNotAvailable
    case nilRecognitionRequest
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Speech recognition is not authorized. Please enable it in Settings."
        case .recognizerNotAvailable:
            return "Speech recognition is not available on this device."
        case .nilRecognitionRequest:
            return "Failed to create recognition request."
        }
    }
}
