//
//  AudioRecorder.swift
//  Talkyo
//
//  Handles audio recording and playback
//

import AVFoundation
import AudioToolbox

// MARK: - Audio Recorder

final class AudioRecorder: NSObject, ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var isRecording = false
    @Published private(set) var hasRecording = false
    @Published private(set) var recordedFileURL: URL?
    
    // MARK: - Private Properties
    
    private var audioEngine: AVAudioEngine?
    private var audioConverter: AVAudioConverter?
    private var audioPlayer: AVAudioPlayer?
    private var audioBuffer: [Float] = []
    
    // MARK: - Callbacks
    
    var onAudioBuffer: ((AVAudioPCMBuffer) -> Void)?
    
    // MARK: - Audio Configuration
    
    private enum Config {
        enum Audio {
            static let sampleRate: Double = 16000
            static let bufferSize: AVAudioFrameCount = 2048
        }
        
        enum Haptic {
            static let start: SystemSoundID = 1519    // Light impact
            static let stop: SystemSoundID = 1520     // Medium impact  
            static let cancel: SystemSoundID = 1521   // Heavy impact
        }
    }
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        configureAudioSession()
        setupAudioEngine()
    }
    
    // MARK: - Public Methods
    
    func startRecording() {
        guard !isRecording else { return }
        
        prepareForRecording()
        playHaptic(Config.Haptic.start)
        
        // Use the fresh engine created in prepareForRecording
        guard let engine = audioEngine else { return }
        beginRecording(with: engine)
    }
    
    func stopRecording() -> [Float] {
        guard isRecording else { return [] }
        
        completeRecording()
        playHaptic(Config.Haptic.stop)
        
        if !audioBuffer.isEmpty {
            saveRecording()
            hasRecording = true
        }
        
        return audioBuffer
    }
    
    func playRecording() {
        guard let url = recordedFileURL,
              FileManager.default.fileExists(atPath: url.path) else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
        } catch {
            print("Playback failed: \(error)")
        }
    }
    
    func cancelRecording() {
        guard isRecording else { return }
        
        completeRecording()
        playHaptic(Config.Haptic.cancel)
        
        // Clear the buffer without saving
        audioBuffer.removeAll()
        recordedFileURL = nil
        hasRecording = false
    }
    
    // MARK: - Private Methods - Setup
    
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        
        AVAudioApplication.requestRecordPermission { granted in
            guard granted else { return }
            
            do {
                try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
                try session.setActive(true)
            } catch {
                print("Audio session setup failed: \(error)")
            }
        }
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
    }
    
    // MARK: - Private Methods - Recording
    
    private func prepareForRecording() {
        // Stop any active playback
        audioPlayer?.stop()
        audioPlayer = nil
        
        // Clear previous data
        audioBuffer.removeAll()
        
        // Reset engine if needed
        if let engine = audioEngine, engine.isRunning {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
            engine.reset()
        }
        
        // Create a fresh audio engine for each recording
        audioEngine = AVAudioEngine()
    }
    
    private func beginRecording(with engine: AVAudioEngine) {
        // Ensure audio session is active
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
            print("Audio session activated successfully")
        } catch {
            print("Failed to activate audio session: \(error)")
            return
        }
        
        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        print("Input format: \(inputFormat)")
        
        guard let recordingFormat = createRecordingFormat(),
              let converter = createAudioConverter(from: inputFormat, to: recordingFormat) else {
            print("Failed to create recording format or converter")
            return
        }
        
        audioConverter = converter
        
        // Install tap to capture audio
        inputNode.installTap(onBus: 0, bufferSize: Config.Audio.bufferSize, format: inputFormat) { [weak self] buffer, _ in
            let frameLength = Int(buffer.frameLength)
            if frameLength > 0 {
                print("Captured buffer with \(frameLength) frames")
            }
            self?.processAudioBuffer(buffer)
            
            // Send original buffer for live transcription (before conversion)
            self?.onAudioBuffer?(buffer)
        }
        
        // Start engine
        do {
            engine.prepare()
            try engine.start()
            isRecording = true
            print("Audio engine started successfully")
        } catch {
            print("Failed to start recording: \(error)")
            inputNode.removeTap(onBus: 0)
        }
    }
    
    private func completeRecording() {
        guard let engine = audioEngine else { return }
        
        isRecording = false
        
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        audioConverter = nil
        
        logRecordingStats()
    }
    
    // MARK: - Private Methods - Audio Processing
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let converter = audioConverter,
              let convertedBuffer = createConvertedBuffer(for: buffer) else { return }
        
        var error: NSError?
        let status = converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        
        guard error == nil, status != .error,
              let channelData = convertedBuffer.floatChannelData else { return }
        
        let samples = Array(UnsafeBufferPointer(
            start: channelData[0],
            count: Int(convertedBuffer.frameLength)
        ))
        
        audioBuffer.append(contentsOf: samples)
    }
    
    // MARK: - Private Methods - File Management
    
    private func saveRecording() {
        guard let format = createRecordingFormat(),
              let buffer = createAudioBuffer(format: format, samples: audioBuffer) else {
            return
        }
        
        let url = generateRecordingURL()
        
        do {
            let file = try AVAudioFile(forWriting: url, settings: format.settings)
            try file.write(from: buffer)
            recordedFileURL = url
        } catch {
            print("Failed to save recording: \(error)")
        }
    }
    
    // MARK: - Private Methods - Helpers
    
    private func createRecordingFormat() -> AVAudioFormat? {
        AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: Config.Audio.sampleRate,
            channels: 1,
            interleaved: false
        )
    }
    
    private func createAudioConverter(from inputFormat: AVAudioFormat, to outputFormat: AVAudioFormat) -> AVAudioConverter? {
        AVAudioConverter(from: inputFormat, to: outputFormat)
    }
    
    private func createConvertedBuffer(for sourceBuffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard let format = createRecordingFormat() else { return nil }
        
        let frameCapacity = AVAudioFrameCount(
            Double(sourceBuffer.frameLength) * Config.Audio.sampleRate / sourceBuffer.format.sampleRate
        )
        
        return AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCapacity)
    }
    
    private func createAudioBuffer(format: AVAudioFormat, samples: [Float]) -> AVAudioPCMBuffer? {
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(samples.count)
        ) else { return nil }
        
        buffer.frameLength = buffer.frameCapacity
        
        if let channelData = buffer.floatChannelData {
            channelData[0].update(from: samples, count: samples.count)
        }
        
        return buffer
    }
    
    private func generateRecordingURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("recording.wav")
    }
    
    private func playHaptic(_ hapticID: SystemSoundID) {
        AudioServicesPlaySystemSound(hapticID)
    }
    
    private func logRecordingStats() {
        let duration = Double(audioBuffer.count) / Config.Audio.sampleRate
        let sampleCount = audioBuffer.count
        
        print("""
        Recording completed:
        - Duration: \(String(format: "%.2f", duration))s
        - Samples: \(sampleCount)
        - Sample rate: \(Int(Config.Audio.sampleRate))Hz
        """)
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioRecorder: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Handle playback completion if needed
    }
}