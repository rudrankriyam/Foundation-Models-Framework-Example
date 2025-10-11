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

    @Published private(set) var isSpeaking = false
    @Published private(set) var error: SpeechSynthesizerError?

    private let synthesizer = AVSpeechSynthesizer()
    private var currentUtterance: AVSpeechUtterance?
    private var currentAudioURL: URL?
    private var audioSessionConfigured = false
    private var pendingContinuation: CheckedContinuation<Void, Error>?
    private var pendingFileContinuation: CheckedContinuation<URL, Error>?

    @Published var selectedVoice: AVSpeechSynthesisVoice?
    @Published var availableVoices: [AVSpeechSynthesisVoice] = []
    @Published var voicesByLanguage: [String: [AVSpeechSynthesisVoice]] = [:]
    @Published var availableLanguages: [String] = []
    private let volume: Float

    init(volume: Float = 1.0) {
        self.volume = max(0.0, min(1.0, volume))

        super.init()

        synthesizer.delegate = self
        setupAudioSession()
        loadAvailableVoices()
        preWarmSynthesizer()
    }

    func synthesizeAndSpeak(text: String) async throws {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SpeechSynthesizerError.invalidInput
        }

        guard !isSpeaking else {
            throw SpeechSynthesizerError.alreadySpeaking
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.pendingContinuation = continuation

            let utterance = self.createUtterance(from: text)
            self.startSynthesis(utterance: utterance)
        }
    }

    func generateAudioFile(text: String) async throws -> URL {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SpeechSynthesizerError.invalidInput
        }

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            guard let outputURL = createAudioFile() else {
                continuation.resume(throwing: SpeechSynthesizerError.audioFileCreationFailed)
                return
            }

            self.currentAudioURL = outputURL
            self.pendingFileContinuation = continuation

            let utterance = self.createUtterance(from: text)

            // For now, we'll use the same synthesis but mark that we want to save to file
            // In a full implementation, you'd use AVAudioEngine or similar to capture the output
            // For this demo, we'll just speak and assume the file is created
            startSynthesis(utterance: utterance)
        }
    }

    private func setupAudioSession() {
        configurePlaybackSession()
    }

    private func preWarmSynthesizer() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)

            if let voice = self.selectedVoice ?? AVSpeechSynthesisVoice(language: "en-US") {
                let warmUpUtterance = AVSpeechUtterance(string: ".")
                warmUpUtterance.voice = voice
                warmUpUtterance.volume = 0.01
                warmUpUtterance.rate = 0.1
                warmUpUtterance.pitchMultiplier = 1.0

                self.synthesizer.speak(warmUpUtterance)
                print("🔊 Pre-warmed speech synthesizer with \(voice.name)")
            }
        }
    }

    private func configurePlaybackSession() {
        #if os(iOS)
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers])
            try audioSession.setActive(true, options: [])
            audioSessionConfigured = true
            print("🔊 Configured audio session for speech synthesis playback")
        } catch {
            print("🔊 Failed to configure audio session for playback: \(error.localizedDescription)")
        }
        #endif
    }

    func loadAvailableVoices() {
        Task { @MainActor in
            let allVoices = AVSpeechSynthesisVoice.speechVoices()
            var voicesGroupedByLanguage: [String: [AVSpeechSynthesisVoice]] = [:]

            for voice in allVoices {
                let languageCode = voice.language
                voicesGroupedByLanguage[languageCode, default: []].append(voice)
            }

            for (language, voices) in voicesGroupedByLanguage {
                voicesGroupedByLanguage[language] = voices.sorted { voice1, voice2 in
                    if voice1.quality != voice2.quality {
                        return voice1.quality.rawValue > voice2.quality.rawValue
                    }
                    return voice1.name < voice2.name
                }
            }

            voicesByLanguage = voicesGroupedByLanguage
            availableLanguages = voicesGroupedByLanguage.keys.sorted { lang1, lang2 in
                if lang1.hasPrefix("en") && !lang2.hasPrefix("en") {
                    return true
                } else if !lang1.hasPrefix("en") && lang2.hasPrefix("en") {
                    return false
                }
                return lang1 < lang2
            }

            let englishVoices = allVoices.filter { $0.language.hasPrefix("en") }
                .sorted { voice1, voice2 in
                    if voice1.quality != voice2.quality {
                        return voice1.quality.rawValue > voice2.quality.rawValue
                    }
                    return voice1.name < voice2.name
                }

            availableVoices = englishVoices
            let avaVoice = englishVoices.first { $0.name == "Ava" }
            selectedVoice = avaVoice ?? englishVoices.first ?? AVSpeechSynthesisVoice(language: "en-US")

            if let voice = selectedVoice {
                print("Selected voice: \(voice.name) (\(voice.language)) - Quality: \(voice.quality.rawValue)")
                let voiceSummaries = englishVoices.map { "\($0.name) (Q:\($0.quality.rawValue))" }
                print("Available voices: \(voiceSummaries.joined(separator: ", "))")
            }
        }
    }

    private func createUtterance(from text: String) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = selectedVoice ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.volume = max(0.0, min(1.0, volume))

        let voiceName = utterance.voice?.name ?? "default"
        print(
            "Created utterance: text='\(text)', voice=\(voiceName), rate=\(utterance.rate), " +
            "pitch=\(utterance.pitchMultiplier), volume=\(utterance.volume)"
        )

        return utterance
    }

    private func startSynthesis(utterance: AVSpeechUtterance) {
        currentUtterance = utterance
        isSpeaking = true
        error = nil

        print("Starting speech synthesis: '\(utterance.speechString)'")
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
        pendingContinuation = nil
        pendingFileContinuation = nil
    }

    private func handleSuccess() {
        print("Speech synthesis completed successfully")

        #if os(iOS)
        Task.detached {
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                print("Deactivated audio session after speech synthesis")
            } catch {
                print("Failed to deactivate audio session: \(error.localizedDescription)")
            }
        }
        #endif

        if let continuation = pendingContinuation {
            continuation.resume()
            pendingContinuation = nil
        } else if let fileContinuation = pendingFileContinuation,
                  let audioURL = currentAudioURL {
            fileContinuation.resume(returning: audioURL)
            pendingFileContinuation = nil
        }

        resetState()
    }

    private func handleError(_ synthError: SpeechSynthesizerError) {
        error = synthError

        #if os(iOS)
        Task.detached {
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                print("Deactivated audio session after speech synthesis error")
            } catch {
                print("Failed to deactivate audio session: \(error.localizedDescription)")
            }
        }
        #endif

        if let continuation = pendingContinuation {
            continuation.resume(throwing: synthError)
            pendingContinuation = nil
        } else if let fileContinuation = pendingFileContinuation {
            fileContinuation.resume(throwing: synthError)
            pendingFileContinuation = nil
        }

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
        case .cancelled:
            return "Speech synthesis was cancelled"
        }
    }
}
