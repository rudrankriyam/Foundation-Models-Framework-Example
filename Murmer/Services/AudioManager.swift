//
//  AudioManager.swift
//  Murmer
//
//  Created by Rudrank Riyam on 6/26/25.
//

import AVFoundation
import Accelerate
import Combine
#if os(iOS)
import UIKit
#endif

class AudioManager: ObservableObject {
    @Published var currentAmplitude: Double = 0
    @Published var isRecording = false

    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioFormat: AVAudioFormat?

    // Smoothing parameters
    private var amplitudeHistory: [Double] = []
    private let historySize = 10
    private let smoothingFactor = 0.8

    private var updateTimer: Timer?

    init() {
        setupAudioSession()
    }

    deinit {
        stopAudioSession()
    }

    private func setupAudioSession() {

#if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(
                .playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
            try audioSession.setActive(true)

            // Request microphone permission
            Task {
                let granted = await AVAudioApplication.requestRecordPermission()
                if granted {
                    self.setupAudioEngine()
                } else {
                }
            }
        } catch {
        }
#elseif os(macOS)
        // On macOS, we don't have AVAudioSession, just set up the engine directly
        setupAudioEngine()
#endif
    }


    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            return
        }

        inputNode = audioEngine.inputNode
        audioFormat = inputNode?.inputFormat(forBus: 0)

        guard let audioFormat = audioFormat else {
            return
        }

        // Don't install tap here - will be installed when needed to avoid conflicts
        print("🎤 AudioEngine setup completed, tap will be installed when needed")
    }

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else {
            return
        }
        let frameLength = Int(buffer.frameLength)

        // Calculate RMS amplitude
        var rms: Float = 0
        vDSP_rmsqv(channelData, 1, &rms, vDSP_Length(frameLength))

        // Smooth the amplitude using logarithmic scale for better dynamic range
        let normalizedAmplitude = Double(min(log10(1 + rms * 9), 1.0))
        let smoothedAmplitude = smoothAmplitude(normalizedAmplitude)

        // Log audio levels periodically (every 50th buffer to avoid spam)
        if Int.random(in: 0..<50) == 0 {
        }

        // Update on main thread
        DispatchQueue.main.async {
            self.currentAmplitude = smoothedAmplitude
        }
    }

    private func smoothAmplitude(_ newAmplitude: Double) -> Double {
        amplitudeHistory.append(newAmplitude)
        if amplitudeHistory.count > historySize {
            amplitudeHistory.removeFirst()
        }

        // Apply exponential smoothing
        var smoothed = amplitudeHistory[0]
        for i in 1..<amplitudeHistory.count {
            smoothed = smoothed * smoothingFactor + amplitudeHistory[i] * (1 - smoothingFactor)
        }

        // Log significant amplitude changes
        if abs(smoothed - (amplitudeHistory.last ?? 0)) > 0.1 {
        }

        return smoothed
    }


    func startAudioSession() {
        print("🎤 AudioManager startAudioSession called")
        guard let audioEngine = audioEngine else {
            setupAudioEngine()
            return
        }

        guard let inputNode = inputNode, let audioFormat = audioFormat else {
            print("🎤 AudioManager: Missing inputNode or audioFormat")
            return
        }

        // Only start if not already running and not conflicting with speech recognition
        guard !audioEngine.isRunning else {
            print("🎤 AudioManager: Audio engine already running")
            isRecording = true
            return
        }

        do {
            // Install tap for amplitude monitoring
            let bufferSize = AVAudioFrameCount(1024)
            inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: audioFormat) {
                [weak self] buffer, _ in
                self?.processAudioBuffer(buffer)
            }
            
            try audioEngine.start()
            isRecording = true
            print("🎤 AudioManager: Audio session started successfully")
        } catch {
            print("🎤 AudioManager: Failed to start audio session: \(error.localizedDescription)")
        }
    }

    func stopAudioSession() {
        print("🎤 AudioManager stopAudioSession called")

        if let audioEngine = audioEngine, audioEngine.isRunning {
            audioEngine.stop()
            print("🎤 AudioManager: Audio engine stopped")
        } else {
            print("🎤 AudioManager: Audio engine was not running")
        }

        if let inputNode = inputNode {
            // Safely remove tap if it exists
            if inputNode.numberOfInputs > 0 {
                do {
                    inputNode.removeTap(onBus: 0)
                    print("🎤 AudioManager: Audio tap removed successfully")
                } catch {
                    print("🎤 AudioManager: Error removing audio tap: \(error.localizedDescription)")
                }
            }
        } else {
            print("🎤 AudioManager: No input node to remove tap from")
        }

        isRecording = false
        currentAmplitude = 0
        print("🎤 AudioManager: Stop audio session completed")
    }
}
