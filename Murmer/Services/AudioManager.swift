//
//  AudioManager.swift
//  Murmer
//
//  Created by Rudrank Riyam on 6/26/25.
//

import AVFoundation
import Combine
import Accelerate

class AudioManager: ObservableObject {
    @Published var currentAmplitude: Double = 0
    @Published var frequencyData: [Float] = []
    @Published var isRecording = false
    
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioFormat: AVAudioFormat?
    
    // FFT properties for frequency analysis
    private var fftSetup: FFTSetup?
    private let fftLength = 2048
    private var window: [Float] = []
    
    // Smoothing parameters
    private var amplitudeHistory: [Double] = []
    private let historySize = 10
    private let smoothingFactor = 0.8
    
    private var updateTimer: Timer?
    
    init() {
        setupAudioSession()
        setupFFT()
    }
    
    deinit {
        stopAudioSession()
        if let fftSetup = fftSetup {
            vDSP_destroy_fftsetup(fftSetup)
        }
    }
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
            try audioSession.setActive(true)
            
            // Request microphone permission
            audioSession.requestRecordPermission { [weak self] granted in
                if granted {
                    self?.setupAudioEngine()
                } else {
                    print("Microphone permission denied")
                }
            }
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func setupFFT() {
        let log2n = vDSP_Length(log2f(Float(fftLength)))
        fftSetup = vDSP_create_fftsetup(log2n, Int32(kFFTRadix2))
        
        // Create Hanning window for better frequency resolution
        window = [Float](repeating: 0, count: fftLength)
        vDSP_hann_window(&window, vDSP_Length(fftLength), Int32(vDSP_HANN_NORM))
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        
        inputNode = audioEngine.inputNode
        audioFormat = inputNode?.inputFormat(forBus: 0)
        
        guard let audioFormat = audioFormat else { return }
        
        // Install tap on input node to capture audio
        let bufferSize = AVAudioFrameCount(fftLength)
        inputNode?.installTap(onBus: 0, bufferSize: bufferSize, format: audioFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        
        // Calculate RMS amplitude
        var rms: Float = 0
        vDSP_rmsqv(channelData, 1, &rms, vDSP_Length(frameLength))
        
        // Smooth the amplitude
        let normalizedAmplitude = Double(min(rms * 10, 1.0))
        let smoothedAmplitude = smoothAmplitude(normalizedAmplitude)
        
        // Perform FFT for frequency analysis
        performFFT(channelData, frameLength: frameLength)
        
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
        
        return smoothed
    }
    
    private func performFFT(_ data: UnsafeMutablePointer<Float>, frameLength: Int) {
        guard let fftSetup = fftSetup, frameLength >= fftLength else { return }
        
        // Apply window
        var windowedData = [Float](repeating: 0, count: fftLength)
        vDSP_vmul(data, 1, window, 1, &windowedData, 1, vDSP_Length(fftLength))
        
        // Prepare for FFT
        var realp = [Float](repeating: 0, count: fftLength/2)
        var imagp = [Float](repeating: 0, count: fftLength/2)
        var splitComplex = DSPSplitComplex(realp: &realp, imagp: &imagp)
        
        // Convert to split complex format
        windowedData.withUnsafeBytes { ptr in
            let complexPtr = ptr.bindMemory(to: DSPComplex.self)
            vDSP_ctoz(complexPtr.baseAddress!, 2, &splitComplex, 1, vDSP_Length(fftLength/2))
        }
        
        // Perform FFT
        let log2n = vDSP_Length(log2f(Float(fftLength)))
        vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, Int32(FFT_FORWARD))
        
        // Calculate magnitude
        var magnitudes = [Float](repeating: 0, count: fftLength/2)
        vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(fftLength/2))
        
        // Convert to dB and normalize
        var dbMagnitudes = [Float](repeating: 0, count: fftLength/2)
        var zero: Float = 1.0
        vDSP_vdbcon(&magnitudes, 1, &zero, &dbMagnitudes, 1, vDSP_Length(fftLength/2), 0)
        
        // Update frequency data on main thread (take first 64 bins for visualization)
        let visualizationBins = min(64, fftLength/2)
        let frequencySlice = Array(dbMagnitudes[0..<visualizationBins])
        
        DispatchQueue.main.async {
            self.frequencyData = frequencySlice
        }
    }
    
    func startAudioSession() {
        guard let audioEngine = audioEngine else {
            setupAudioEngine()
            return
        }
        
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    func stopAudioSession() {
        audioEngine?.stop()
        inputNode?.removeTap(onBus: 0)
        isRecording = false
        currentAmplitude = 0
        frequencyData = []
    }
}