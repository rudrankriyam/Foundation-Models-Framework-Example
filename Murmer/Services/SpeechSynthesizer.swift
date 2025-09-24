//
//  SpeechSynthesizer.swift
//  Murmer
//
//  Created by Rudrank Riyam on 6/26/25.
//

import AVFoundation
import Combine
import Foundation

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// A service class that handles text-to-speech synthesis
/// Follows the single responsibility principle with one public method
@MainActor
final class SpeechSynthesizer: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var isSpeaking = false
    @Published private(set) var error: SpeechSynthesizerError?

    // MARK: - Private Properties

    private let synthesizer = AVSpeechSynthesizer()
    private var currentUtterance: AVSpeechUtterance?
    private var currentAudioURL: URL?
    private var completion: ((Result<Void, SpeechSynthesizerError>) -> Void)?

    // MARK: - Configuration

    @Published var selectedVoice: AVSpeechSynthesisVoice?
    @Published var availableVoices: [AVSpeechSynthesisVoice] = []
    private let rate: Float
    private let pitch: Float
    private let volume: Float

    // MARK: - Initialization

    init(
        rate: Float = 0.5,
        pitch: Float = 1.0,
        volume: Float = 1.0
    ) {
        self.rate = max(0.0, min(1.0, rate))
        self.pitch = max(0.5, min(2.0, pitch))
        self.volume = max(0.0, min(1.0, volume))

        super.init()

        synthesizer.delegate = self
        setupAudioSession()
        loadAvailableVoices()
    }

    // MARK: - Public API

    /// Converts text to speech and speaks it directly
    func synthesizeAndSpeak(text: String) async throws {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SpeechSynthesizerError.invalidInput
        }

        guard !isSpeaking else {
            throw SpeechSynthesizerError.alreadySpeaking
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.completion = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }

            let utterance = self.createUtterance(from: text)
            self.startSynthesis(utterance: utterance)
        }
    }

    // MARK: - Private Methods

    private func setupAudioSession() {
        #if os(iOS)
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers])
            try audioSession.setActive(true)
        } catch {
            print("[SpeechSynthesizer] Audio session setup failed: \(error)")
        }
        #endif
    }

    func loadAvailableVoices() {
        Task { @MainActor in
            let allVoices = AVSpeechSynthesisVoice.speechVoices()

            // Filter to English premium voices first for best quality
            var selectedVoices = allVoices.filter { voice in
                voice.language.hasPrefix("en") && voice.quality == .premium
            }

            // Fallback to enhanced voices if no premium voices available
            if selectedVoices.isEmpty {
                selectedVoices = allVoices.filter { voice in
                    voice.language.hasPrefix("en") && voice.quality == .enhanced
                }
            }

            // Fallback to any English voices if still empty
            if selectedVoices.isEmpty {
                selectedVoices = allVoices.filter { voice in
                    voice.language.hasPrefix("en")
                }
            }

            // Sort alphabetically
            availableVoices = selectedVoices.sorted { voice1, voice2 in
                return voice1.name < voice2.name
            }

            // Set default voice
            selectedVoice = availableVoices.first ?? AVSpeechSynthesisVoice(language: "en-US")
        }
    }

    private func createUtterance(from text: String) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = selectedVoice ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = rate
        utterance.pitchMultiplier = pitch
        utterance.volume = volume
        return utterance
    }

    private func startSynthesis(utterance: AVSpeechUtterance) {
        currentUtterance = utterance
        isSpeaking = true
        error = nil

        synthesizer.speak(utterance)
    }

    private func createAudioFile() -> URL? {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = "speech_\(UUID().uuidString).caf"
        return tempDirectory.appendingPathComponent(fileName)
    }

    private func resetState() {
        isSpeaking = false
        currentUtterance = nil
        completion = nil
    }

    private func handleSuccess() {
        completion?(.success(()))
        resetState()
    }

    private func handleError(_ synthError: SpeechSynthesizerError) {
        error = synthError
        completion?(.failure(synthError))
        resetState()
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension SpeechSynthesizer: AVSpeechSynthesizerDelegate {

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = true
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.handleSuccess()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.handleError(.cancelled)
        }
    }
}

// MARK: - Error Types

enum SpeechSynthesizerError: LocalizedError {
    case invalidInput
    case alreadySpeaking
    case fileCreationFailed
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Invalid input text"
        case .alreadySpeaking:
            return "Speech synthesis already in progress"
        case .fileCreationFailed:
            return "Failed to create audio file"
        case .cancelled:
            return "Speech synthesis was cancelled"
        }
    }
}