//
//  SpeechSynthesizer.swift
//  Foundation Lab
//
//  Created by Rudrank Riyam on 10/27/25.
//

import AVFoundation
import Foundation
import OSLog

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Speech Synthesis Service Protocol

/// Protocol defining the interface for text-to-speech functionality
@MainActor
protocol SpeechSynthesisService: AnyObject {
    /// Whether speech synthesis is currently active
    var isSpeaking: Bool { get }

    /// Any current error state
    var error: SpeechSynthesizerError? { get }

    /// Handler invoked whenever speaking state changes
    var speakingStateHandler: ((Bool) -> Void)? { get set }

    /// Handler invoked when an unrecoverable error occurs
    var errorHandler: ((SpeechSynthesizerError) -> Void)? { get set }

    /// Available voices organized by language
    var voicesByLanguage: [String: [AVSpeechSynthesisVoice]] { get }

    /// All available languages
    var availableLanguages: [String] { get }

    /// Currently selected voice
    var selectedVoice: AVSpeechSynthesisVoice? { get set }

    /// Convert text to speech and speak it directly
    /// - Parameter text: The text to synthesize and speak
    /// - Throws: SpeechSynthesizerError if synthesis fails
    func synthesizeAndSpeak(text: String) async throws
}

// MARK: - Error Types

enum SpeechSynthesizerError: LocalizedError {
    case invalidInput
    case alreadySpeaking
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Invalid input text"
        case .alreadySpeaking:
            return "Speech synthesis already in progress"
        case .cancelled:
            return "Speech synthesis was cancelled"
        }
    }
}

// MARK: - Speech Synthesizer Implementation

/// A service class that handles text-to-speech synthesis
/// Follows the single responsibility principle with one public method
@MainActor
final class SpeechSynthesizer: NSObject, SpeechSynthesisService {

    static let shared = SpeechSynthesizer()

    var isSpeaking = false
    var error: SpeechSynthesizerError?

    private let logger = VoiceLogging.synthesis
    private let synthesizer = AVSpeechSynthesizer()
    private var currentUtterance: AVSpeechUtterance?
    private var audioSessionConfigured = false
    private var pendingContinuation: CheckedContinuation<Void, Error>?
    var speakingStateHandler: ((Bool) -> Void)?
    var errorHandler: ((SpeechSynthesizerError) -> Void)?

    var selectedVoice: AVSpeechSynthesisVoice?
    var availableVoices: [AVSpeechSynthesisVoice] = []
    var voicesByLanguage: [String: [AVSpeechSynthesisVoice]] = [:]
    var availableLanguages: [String] = []
    private let volume: Float

    private init(volume: Float = 1.0) {
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

    private func setupAudioSession() {
        configurePlaybackSession()
    }

    private func preWarmSynthesizer() {
        // Don't pre-warm automatically - it can cause audio engine conflicts
        // We'll initialize on first use instead
        logger.debug("Speech synthesizer ready for first use")
    }

    private func configurePlaybackSession() {
        #if os(iOS)
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers])
            try audioSession.setActive(true, options: [])
            audioSessionConfigured = true
            logger.debug("Configured audio session for speech synthesis playback")
        } catch {
            logger.error("Failed to configure audio session for playback: \(error.localizedDescription, privacy: .public)")
        }
        #endif
    }

    func loadAvailableVoices() {
        Task { @MainActor in
            let allVoices = AVSpeechSynthesisVoice.speechVoices()
            var voicesGroupedByLanguage: [String: [AVSpeechSynthesisVoice]] = [:]

            // Filter out novelty/system voices and only keep high-quality speech voices
            let speechVoices = allVoices.filter { voice in
                // Filter out novelty voices by checking if they're system voices
                return !voice.name.contains("Bad News") &&
                       !voice.name.contains("Good News") &&
                       !voice.name.contains("Boing") &&
                       !voice.name.contains("Bubbles") &&
                       !voice.name.contains("Jester") &&
                       !voice.name.contains("Junior") &&
                       !voice.name.contains("Ralph") &&
                       !voice.name.contains("Trinoids") &&
                       !voice.name.contains("Whisper") &&
                       !voice.name.contains("Zarvox") &&
                       voice.quality == .enhanced
            }

            for voice in speechVoices {
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

            let englishVoices = speechVoices.filter { $0.language.hasPrefix("en") }
                .sorted { voice1, voice2 in
                    if voice1.quality != voice2.quality {
                        return voice1.quality.rawValue > voice2.quality.rawValue
                    }
                    return voice1.name < voice2.name
                }

            availableVoices = englishVoices.isEmpty ?
                allVoices.filter { $0.language.hasPrefix("en") && $0.quality == .default } :
                englishVoices

            // Prefer common high-quality voices, fall back to any available
            let preferredVoices = ["Samantha", "Karen", "Moira", "Ava", "Alex", "Daniel", "Karen", "Tessa"]
            selectedVoice = preferredVoices.compactMap { name in
                availableVoices.first { $0.name.contains(name) }
            }.first ?? availableVoices.first ?? AVSpeechSynthesisVoice(language: "en-US")

            if VoiceLogging.isVerboseEnabled, let voice = selectedVoice {
                logger.debug("Selected voice: \(voice.name, privacy: .public) (\(voice.language, privacy: .public)) quality=\(voice.quality.rawValue)")
                let summaries = availableVoices.map { "\($0.name) (Q:\($0.quality.rawValue))" }.joined(separator: ", ")
                logger.debug("Available voices: \(summaries, privacy: .public)")
            }
        }
    }

    private func createUtterance(from text: String) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = selectedVoice ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.volume = max(0.0, min(1.0, volume))

        if VoiceLogging.isVerboseEnabled {
            let voiceName = utterance.voice?.name ?? "default"
            logger.debug("Created utterance voice=\(voiceName, privacy: .public) rate=\(utterance.rate, format: .fixed(precision: 2)) pitch=\(utterance.pitchMultiplier, format: .fixed(precision: 2)) volume=\(utterance.volume, format: .fixed(precision: 2))")
        }

        return utterance
    }

    private func startSynthesis(utterance: AVSpeechUtterance) {
        currentUtterance = utterance
        isSpeaking = true
        speakingStateHandler?(true)
        error = nil

        logger.info("Starting speech synthesis")
        synthesizer.speak(utterance)
    }

    private func resetState() {
        isSpeaking = false
        currentUtterance = nil
        pendingContinuation = nil
    }

    private func handleSuccess() {
        logger.info("Speech synthesis completed successfully")

        #if os(iOS)
        Task { @MainActor in
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                logger.debug("Deactivated audio session after speech synthesis")
            } catch {
                logger.error("Failed to deactivate audio session: \(error.localizedDescription, privacy: .public)")
            }
        }
        #endif

        if let continuation = pendingContinuation {
            continuation.resume()
            pendingContinuation = nil
        }

        resetState()
        speakingStateHandler?(false)
    }

    private func handleError(_ synthError: SpeechSynthesizerError) {
        error = synthError
        errorHandler?(synthError)

#if os(iOS)
        Task { @MainActor in
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                logger.debug("Deactivated audio session after speech synthesis error")
            } catch {
                logger.error("Failed to deactivate audio session after error: \(error.localizedDescription, privacy: .public)")
            }
        }
#endif

        if let continuation = pendingContinuation {
            continuation.resume(throwing: synthError)
            pendingContinuation = nil
        }

        resetState()
        speakingStateHandler?(false)
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
