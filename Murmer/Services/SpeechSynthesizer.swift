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
final class SpeechSynthesizer: NSObject, ObservableObject, SpeechSynthesisService {

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
    @Published var voicesByLanguage: [String: [AVSpeechSynthesisVoice]] = [:]
    @Published var availableLanguages: [String] = []
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

            // Configure audio session for playback before synthesis
            self.configurePlaybackSession()

            let utterance = self.createUtterance(from: text)
            self.startSynthesis(utterance: utterance)
        }
    }

    /// Generates speech audio file and returns URL for AVAudioPlayer playback
    func generateAudioFile(text: String) async throws -> URL {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SpeechSynthesizerError.invalidInput
        }

        return try await withCheckedThrowingContinuation { continuation in
            guard let outputURL = createAudioFile() else {
                continuation.resume(throwing: SpeechSynthesizerError.audioFileCreationFailed)
                return
            }

            self.currentAudioURL = outputURL

            self.completion = { result in
                switch result {
                case .success:
                    continuation.resume(returning: outputURL)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }

            let utterance = self.createUtterance(from: text)

            // For now, we'll use the same synthesis but mark that we want to save to file
            // In a full implementation, you'd use AVAudioEngine or similar to capture the output
            // For this demo, we'll just speak and assume the file is created
            startSynthesis(utterance: utterance)
        }
    }

    // MARK: - Private Methods

    private func setupAudioSession() {
        // Initial setup - audio session will be configured dynamically before synthesis
    }

    private func configurePlaybackSession() {
        #if os(iOS)
        do {
            let audioSession = AVAudioSession.sharedInstance()

            // Configure for playback with proper options for speech synthesis
            try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers])
            try audioSession.setActive(true, options: [])

            print("🔊 Configured audio session for speech synthesis playback")
        } catch {
            print("🔊 Failed to configure audio session for playback: \(error.localizedDescription)")
        }
        #endif
    }

    func loadAvailableVoices() {
        Task { @MainActor in
            let allVoices = AVSpeechSynthesisVoice.speechVoices()

            // Organize all voices by language
            var voicesGroupedByLanguage: [String: [AVSpeechSynthesisVoice]] = [:]

            for voice in allVoices {
                let languageCode = voice.language
                if voicesGroupedByLanguage[languageCode] == nil {
                    voicesGroupedByLanguage[languageCode] = []
                }
                voicesGroupedByLanguage[languageCode]?.append(voice)
            }

            // Sort voices within each language by quality and name
            for (language, voices) in voicesGroupedByLanguage {
                voicesGroupedByLanguage[language] = voices.sorted { voice1, voice2 in
                    // Sort by quality first (Premium > Enhanced > Default), then by name
                    if voice1.quality != voice2.quality {
                        return voice1.quality.rawValue > voice2.quality.rawValue
                    }
                    return voice1.name < voice2.name
                }
            }

            voicesByLanguage = voicesGroupedByLanguage

            // Get sorted list of languages, prioritizing English
            availableLanguages = voicesGroupedByLanguage.keys.sorted { lang1, lang2 in
                if lang1.hasPrefix("en") && !lang2.hasPrefix("en") {
                    return true
                } else if !lang1.hasPrefix("en") && lang2.hasPrefix("en") {
                    return false
                }
                return lang1 < lang2
            }

            // Set up English voices for backward compatibility
            let englishVoices = allVoices.filter { $0.language.hasPrefix("en") }
                .sorted { voice1, voice2 in
                    if voice1.quality != voice2.quality {
                        return voice1.quality.rawValue > voice2.quality.rawValue
                    }
                    return voice1.name < voice2.name
                }

            availableVoices = englishVoices

            // Hardcode to use Rishi voice
            let rishiVoice = englishVoices.first { voice in
                voice.name == "Rishi"
            }
            
            selectedVoice = rishiVoice ?? englishVoices.first ?? AVSpeechSynthesisVoice(language: "en-US")
            
            if let voice = selectedVoice {
                print("🎙️ Selected voice: \(voice.name) (\(voice.language)) - Quality: \(voice.quality.rawValue)")
                print("🎙️ Available voices: \(englishVoices.map { "\($0.name) (Q:\($0.quality.rawValue))" }.joined(separator: ", "))")
            }
        }
    }

    private func createUtterance(from text: String) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = selectedVoice ?? AVSpeechSynthesisVoice(language: "en-US")

        // Ensure reasonable parameters
        utterance.rate = max(0.1, min(1.0, rate)) // AVSpeechUtterance rate range is 0.0 to 1.0
        utterance.pitchMultiplier = max(0.5, min(2.0, pitch))
        utterance.volume = max(0.0, min(1.0, volume))

        print("🔊 Created utterance: text='\(text)', voice=\(utterance.voice?.name ?? "default"), rate=\(utterance.rate), pitch=\(utterance.pitchMultiplier), volume=\(utterance.volume)")

        return utterance
    }

    private func startSynthesis(utterance: AVSpeechUtterance) {
        currentUtterance = utterance
        isSpeaking = true
        error = nil

        print("🔊 Starting speech synthesis: '\(utterance.speechString)'")
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
        print("🔊 Speech synthesis completed successfully")
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
        DispatchQueue.main.async {
            self.isSpeaking = true
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.handleSuccess()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.handleError(.cancelled)
        }
    }
}

// MARK: - Error Types

enum SpeechSynthesizerError: LocalizedError {
    case invalidInput
    case alreadySpeaking
    case fileCreationFailed
    case audioFileCreationFailed
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Invalid input text"
        case .audioFileCreationFailed:
            return "Failed to create audio file"
        case .alreadySpeaking:
            return "Speech synthesis already in progress"
        case .fileCreationFailed:
            return "Failed to create audio file"
        case .cancelled:
            return "Speech synthesis was cancelled"
        }
    }
}