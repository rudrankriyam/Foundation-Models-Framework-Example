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
        print("[AudioManager] Initializing AudioManager")
        setupAudioSession()
        setupFFT()
        print("[AudioManager] Initialization complete")
    }
    
    deinit {
        print("[AudioManager] Deinitializing AudioManager")
        stopAudioSession()
        if let fftSetup = fftSetup {
            vDSP_destroy_fftsetup(fftSetup)
            print("[AudioManager] FFT setup destroyed")
        }
    }
    
    private func setupAudioSession() {
        print("[AudioManager] Setting up audio session")
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            print("[AudioManager] Setting audio category to playAndRecord")
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
            print("[AudioManager] Activating audio session")
            try audioSession.setActive(true)
            print("[AudioManager] Audio session activated successfully")
            
            // Request microphone permission
            print("[AudioManager] Requesting microphone permission")
            audioSession.requestRecordPermission { [weak self] granted in
                if granted {
                    print("[AudioManager] Microphone permission granted")
                    self?.setupAudioEngine()
                } else {
                    print("[AudioManager] ERROR: Microphone permission denied")
                }
            }
        } catch {
            print("[AudioManager] ERROR: Failed to setup audio session: \(error)")
        }
    }
    
    private func setupFFT() {
        print("[AudioManager] Setting up FFT with length: \(fftLength)")
        let log2n = vDSP_Length(log2f(Float(fftLength)))
        fftSetup = vDSP_create_fftsetup(log2n, Int32(kFFTRadix2))
        
        if fftSetup != nil {
            print("[AudioManager] FFT setup created successfully")
        } else {
            print("[AudioManager] ERROR: Failed to create FFT setup")
        }
        
        // Create Hanning window for better frequency resolution
        window = [Float](repeating: 0, count: fftLength)
        vDSP_hann_window(&window, vDSP_Length(fftLength), Int32(vDSP_HANN_NORM))
        print("[AudioManager] Hanning window created")
    }
    
    private func setupAudioEngine() {
        print("[AudioManager] Setting up audio engine")
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            print("[AudioManager] ERROR: Failed to create audio engine")
            return
        }
        print("[AudioManager] Audio engine created")
        
        inputNode = audioEngine.inputNode
        audioFormat = inputNode?.inputFormat(forBus: 0)
        
        guard let audioFormat = audioFormat else {
            print("[AudioManager] ERROR: Failed to get audio format")
            return
        }
        
        print("[AudioManager] Audio format: \(audioFormat)")
        print("[AudioManager] Sample rate: \(audioFormat.sampleRate) Hz")
        print("[AudioManager] Channels: \(audioFormat.channelCount)")
        
        // Install tap on input node to capture audio
        let bufferSize = AVAudioFrameCount(fftLength)
        print("[AudioManager] Installing audio tap with buffer size: \(bufferSize)")
        inputNode?.installTap(onBus: 0, bufferSize: bufferSize, format: audioFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
        print("[AudioManager] Audio tap installed successfully")
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else {
            print("[AudioManager] ERROR: No channel data in buffer")
            return
        }
        let frameLength = Int(buffer.frameLength)
        
        // Calculate RMS amplitude
        var rms: Float = 0
        vDSP_rmsqv(channelData, 1, &rms, vDSP_Length(frameLength))
        
        // Smooth the amplitude
        let normalizedAmplitude = Double(min(rms * 10, 1.0))
        let smoothedAmplitude = smoothAmplitude(normalizedAmplitude)
        
        // Log audio levels periodically (every 50th buffer to avoid spam)
        if Int.random(in: 0..<50) == 0 {
            print("[AudioManager] Audio level - RMS: \(rms), Normalized: \(normalizedAmplitude), Smoothed: \(smoothedAmplitude)")
        }
        
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
        
        // Log significant amplitude changes
        if abs(smoothed - (amplitudeHistory.last ?? 0)) > 0.1 {
            print("[AudioManager] Significant amplitude change detected: \(smoothed)")
        }
        
        return smoothed
    }
    
    private func performFFT(_ data: UnsafeMutablePointer<Float>, frameLength: Int) {
        guard let fftSetup = fftSetup, frameLength >= fftLength else {
            if fftSetup == nil {
                print("[AudioManager] ERROR: FFT setup is nil")
            }
            if frameLength < fftLength {
                print("[AudioManager] ERROR: Frame length (\(frameLength)) is less than FFT length (\(fftLength))")
            }
            return
        }
        
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
        print("[AudioManager] Starting audio session")
        guard let audioEngine = audioEngine else {
            print("[AudioManager] Audio engine not initialized, setting up now")
            setupAudioEngine()
            return
        }
        
        do {
            print("[AudioManager] Starting audio engine")
            try audioEngine.start()
            isRecording = true
            print("[AudioManager] Audio engine started successfully, isRecording = \(isRecording)")
        } catch {
            print("[AudioManager] ERROR: Failed to start audio engine: \(error)")
            print("[AudioManager] Error details: \(error.localizedDescription)")
        }
    }
    
    func stopAudioSession() {
        print("[AudioManager] Stopping audio session")
        
        if let audioEngine = audioEngine {
            audioEngine.stop()
            print("[AudioManager] Audio engine stopped")
        } else {
            print("[AudioManager] Audio engine was nil")
        }
        
        if let inputNode = inputNode {
            inputNode.removeTap(onBus: 0)
            print("[AudioManager] Audio tap removed")
        } else {
            print("[AudioManager] Input node was nil")
        }
        
        isRecording = false
        currentAmplitude = 0
        frequencyData = []
        print("[AudioManager] Audio session stopped, isRecording = \(isRecording)")
    }
}