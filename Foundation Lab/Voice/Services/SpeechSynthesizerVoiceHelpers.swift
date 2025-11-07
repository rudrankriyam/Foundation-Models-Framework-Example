//
//  SpeechSynthesizerVoiceHelpers.swift
//  Foundation Lab
//
//  Created by Rudrank Riyam on 10/27/25.
//

import AVFoundation
import OSLog

extension SpeechSynthesizer {
    func filterSpeechVoices(from allVoices: [AVSpeechSynthesisVoice]) -> [AVSpeechSynthesisVoice] {
        return allVoices.filter { voice in
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
    }

    func groupVoicesByLanguage(_ speechVoices: [AVSpeechSynthesisVoice]) -> [String: [AVSpeechSynthesisVoice]] {
        var voicesGroupedByLanguage: [String: [AVSpeechSynthesisVoice]] = [:]
        for voice in speechVoices {
            let languageCode = voice.language
            voicesGroupedByLanguage[languageCode, default: []].append(voice)
        }
        return voicesGroupedByLanguage
    }

    func sortVoicesWithinLanguages(
        _ voicesGroupedByLanguage: [String: [AVSpeechSynthesisVoice]]
    ) -> [String: [AVSpeechSynthesisVoice]] {
        var sorted = voicesGroupedByLanguage
        for (language, voices) in voicesGroupedByLanguage {
            sorted[language] = voices.sorted { voice1, voice2 in
                if voice1.quality != voice2.quality {
                    return voice1.quality.rawValue > voice2.quality.rawValue
                }
                return voice1.name < voice2.name
            }
        }
        return sorted
    }

    func sortLanguages(_ languages: Set<String>) -> [String] {
        return languages.sorted { lang1, lang2 in
            if lang1.hasPrefix("en") && !lang2.hasPrefix("en") {
                return true
            } else if !lang1.hasPrefix("en") && lang2.hasPrefix("en") {
                return false
            }
            return lang1 < lang2
        }
    }

    func filterAndSortEnglishVoices(
        from speechVoices: [AVSpeechSynthesisVoice],
        allVoices: [AVSpeechSynthesisVoice]
    ) -> [AVSpeechSynthesisVoice] {
        let englishVoices = speechVoices.filter { $0.language.hasPrefix("en") }
            .sorted { voice1, voice2 in
                if voice1.quality != voice2.quality {
                    return voice1.quality.rawValue > voice2.quality.rawValue
                }
                return voice1.name < voice2.name
            }

        return englishVoices.isEmpty ?
            allVoices.filter { $0.language.hasPrefix("en") && $0.quality == .default } :
            englishVoices
    }

    func selectPreferredVoice(from availableVoices: [AVSpeechSynthesisVoice]) -> AVSpeechSynthesisVoice? {
        let preferredVoices = ["Samantha", "Karen", "Moira", "Ava", "Alex", "Daniel", "Karen", "Tessa"]
        return preferredVoices.compactMap { name in
            availableVoices.first { $0.name.contains(name) }
        }.first ?? availableVoices.first ?? AVSpeechSynthesisVoice(language: "en-US")
    }
}
