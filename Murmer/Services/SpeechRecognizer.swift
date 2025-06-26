//
//  SpeechRecognizer.swift
//  Murmer
//
//  Created by Rudrank Riyam on 6/26/25.
//

import Foundation
import Speech
import AVFoundation
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
    
    override init() {
        super.init()
        speechRecognizer?.delegate = self
    }
    
    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { authStatus in
                Task { @MainActor in
                    switch authStatus {
                    case .authorized:
                        self.hasPermission = true
                        continuation.resume(returning: true)
                    case .denied, .restricted:
                        self.hasPermission = false
                        self.error = SpeechRecognizerError.notAuthorized
                        continuation.resume(returning: false)
                    case .notDetermined:
                        self.hasPermission = false
                        continuation.resume(returning: false)
                    @unknown default:
                        self.hasPermission = false
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }
    
    func startRecognition() throws {
        guard hasPermission else {
            throw SpeechRecognizerError.notAuthorized
        }
        
        guard speechRecognizer?.isAvailable ?? false else {
            throw SpeechRecognizerError.recognizerNotAvailable
        }
        
        // Cancel any ongoing recognition
        stopRecognition()
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Create and configure recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechRecognizerError.nilRecognitionRequest
        }
        
        // Configure request
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false
        
        if #available(iOS 16.0, *) {
            recognitionRequest.addsPunctuation = true
        }
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let result = result {
                Task { @MainActor in
                    self.partialText = result.bestTranscription.formattedString
                    isFinal = result.isFinal
                    
                    if isFinal {
                        self.recognizedText = result.bestTranscription.formattedString
                    }
                }
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                Task { @MainActor in
                    self.isRecognizing = false
                    if let error = error {
                        self.error = error
                    }
                }
            }
        }
        
        // Configure audio input
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        isRecognizing = true
        partialText = ""
        recognizedText = ""
        error = nil
    }
    
    func stopRecognition() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isRecognizing = false
    }
}

// MARK: - SFSpeechRecognizerDelegate
extension SpeechRecognizer: SFSpeechRecognizerDelegate {
    nonisolated func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        Task { @MainActor in
            if !available {
                self.error = SpeechRecognizerError.recognizerNotAvailable
                self.stopRecognition()
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