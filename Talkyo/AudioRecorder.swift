//
//  AudioRecorder.swift
//  Talkyo
//
//  Handles audio recording and playback
//

import AVFoundation
import AudioToolbox

class AudioRecorder: NSObject, ObservableObject {
    private var audioEngine: AVAudioEngine?
    private var audioConverter: AVAudioConverter?
    private var audioPlayer: AVAudioPlayer?
    
    @Published var isRecording = false
    @Published var hasRecording = false
    
    private var audioData: [Float] = []
    private(set) var recordedFileURL: URL?
    
    private let sampleRate: Double = 16000
    private let bufferSize: AVAudioFrameCount = 2048
    
    // System sound IDs for beeps
    private let startBeepSound: SystemSoundID = 1113  // Begin recording sound
    private let stopBeepSound: SystemSoundID = 1114   // End recording sound
    
    override init() {
        super.init()
        setupAudioSession()
        setupAudioEngine()
    }
    
    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            if granted {
                do {
                    try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
                    try session.setActive(true)
                    print("Audio session configured")
                } catch {
                    print("Failed to setup audio session: \(error)")
                }
            }
        }
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
    }
    
    func startRecording() {
        guard let audioEngine = audioEngine,
              !isRecording else { return }
        
        let inputNode = audioEngine.inputNode
        
        // Play start beep
        AudioServicesPlaySystemSound(startBeepSound)
        
        // Stop any playing audio
        audioPlayer?.stop()
        audioPlayer = nil
        
        // Clear previous data
        audioData.removeAll()
        
        // Ensure engine is ready
        if audioEngine.isRunning {
            inputNode.removeTap(onBus: 0)
            audioEngine.stop()
            audioEngine.reset()
        }
        
        // Delay to let beep finish completely before recording (system sounds can be ~0.3-0.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.startRecordingAfterBeep(audioEngine: audioEngine, inputNode: inputNode)
        }
    }
    
    private func startRecordingAfterBeep(audioEngine: AVAudioEngine, inputNode: AVAudioInputNode) {
        // Setup audio format conversion
        let inputFormat = inputNode.outputFormat(forBus: 0)
        let recordingFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        )!
        
        audioConverter = AVAudioConverter(from: inputFormat, to: recordingFormat)
        
        // Install tap
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
        
        // Start engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
            print("Recording started")
        } catch {
            print("Failed to start recording: \(error)")
            inputNode.removeTap(onBus: 0)
        }
    }
    
    func stopRecording() -> [Float] {
        guard let audioEngine = audioEngine,
              isRecording else { return [] }
        
        let inputNode = audioEngine.inputNode
        
        isRecording = false
        
        inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        audioEngine.reset()
        audioConverter = nil
        
        let duration = Double(audioData.count) / sampleRate
        print("📊 Recording stopped:")
        print("   - Samples: \(audioData.count)")
        print("   - Duration: \(String(format: "%.2f", duration)) seconds")
        print("   - Sample rate: \(sampleRate) Hz")
        
        // Play stop beep after recording stops
        AudioServicesPlaySystemSound(stopBeepSound)
        
        if !audioData.isEmpty {
            saveRecording()
            hasRecording = true
        }
        
        return audioData
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let converter = audioConverter else { return }
        
        let outputFrameCapacity = AVAudioFrameCount(
            Double(buffer.frameLength) * sampleRate / buffer.format.sampleRate
        )
        
        guard let convertedBuffer = AVAudioPCMBuffer(
            pcmFormat: AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: sampleRate,
                channels: 1,
                interleaved: false
            )!,
            frameCapacity: outputFrameCapacity
        ) else { return }
        
        var error: NSError?
        converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        
        if error == nil, let channelData = convertedBuffer.floatChannelData {
            let samples = Array(UnsafeBufferPointer(
                start: channelData.pointee,
                count: Int(convertedBuffer.frameLength)
            ))
            audioData.append(contentsOf: samples)
        }
    }
    
    private func saveRecording() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        recordedFileURL = documentsPath.appendingPathComponent("recording.wav")
        
        guard let url = recordedFileURL else { return }
        
        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        )!
        
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(audioData.count)
        ) else { 
            print("❌ Failed to create audio buffer")
            return 
        }
        
        buffer.frameLength = buffer.frameCapacity
        if let channelData = buffer.floatChannelData {
            channelData[0].update(from: audioData, count: audioData.count)
        }
        
        do {
            let file = try AVAudioFile(forWriting: url, settings: format.settings)
            try file.write(from: buffer)
            print("✅ Recording saved to: \(url.lastPathComponent)")
            print("   - File size: \(audioData.count * 4) bytes")
        } catch {
            print("❌ Failed to save recording: \(error)")
        }
    }
    
    func playRecording() {
        guard let url = recordedFileURL,
              FileManager.default.fileExists(atPath: url.path) else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            print("Playing recording")
        } catch {
            print("Failed to play recording: \(error)")
        }
    }
}