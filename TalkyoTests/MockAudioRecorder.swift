//
//  MockAudioRecorder.swift
//  TalkyoTests
//
//  Mock AudioRecorder for testing
//

import AVFoundation
import Foundation

@MainActor
final class MockAudioRecorder: ObservableObject, AudioRecorderProtocol {
    // MARK: - Published Properties
    
    @Published private(set) var isRecording = false
    @Published private(set) var hasRecording = false
    @Published private(set) var recordedFileURL: URL?
    
    // MARK: - Properties
    
    var onAudioBuffer: ((AVAudioPCMBuffer) -> Void)?
    private var testAudioData: [Float] = []
    private var simulateRecordingTimer: Timer?
    
    // MARK: - Test Configuration
    
    private var testAudioFiles: [String: TestAudioMetadata] = [:]
    private var currentTestFile: String?
    
    struct TestAudioMetadata {
        let filename: String
        let audioData: [Float]
        let expectedTranscription: String
    }
    
    // MARK: - Public Methods
    
    func loadTestAudio(named filename: String, expectedTranscription: String = "") {
        // In a real implementation, this would load the actual audio file
        // For testing purposes, we'll simulate audio data
        let mockAudioData = generateMockAudioData(for: filename)
        
        testAudioFiles[filename] = TestAudioMetadata(
            filename: filename,
            audioData: mockAudioData,
            expectedTranscription: expectedTranscription
        )
        
        currentTestFile = filename
        print("MockAudioRecorder: Loaded test audio '\(filename)' with \(mockAudioData.count) samples")
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        isRecording = true
        testAudioData.removeAll()
        
        // Simulate recording with the loaded test data
        if let testFile = currentTestFile,
           let metadata = testAudioFiles[testFile] {
            simulateAudioRecording(with: metadata.audioData)
        }
        
        print("MockAudioRecorder: Started recording")
    }
    
    func stopRecording() -> [Float] {
        guard isRecording else { return [] }
        
        isRecording = false
        simulateRecordingTimer?.invalidate()
        
        if !testAudioData.isEmpty {
            createMockRecordingFile()
            hasRecording = true
        }
        
        print("MockAudioRecorder: Stopped recording with \(testAudioData.count) samples")
        return testAudioData
    }
    
    func cancelRecording() {
        guard isRecording else { return }
        
        isRecording = false
        simulateRecordingTimer?.invalidate()
        
        testAudioData.removeAll()
        recordedFileURL = nil
        hasRecording = false
        
        print("MockAudioRecorder: Cancelled recording")
    }
    
    func playRecording() {
        guard hasRecording else { return }
        print("MockAudioRecorder: Playing recording (simulated)")
    }
    
    // MARK: - Private Methods
    
    private func generateMockAudioData(for filename: String) -> [Float] {
        // Generate different mock audio patterns based on filename
        let sampleRate: Int = 16000
        let duration: Double
        
        switch filename {
        case "konnichiwa.wav":
            duration = 1.5
        case "arigatou.wav":
            duration = 2.5
        case "sayounara.wav":
            duration = 2.0
        case "weather.wav":
            duration = 3.0
        case "library.wav":
            duration = 3.5
        default:
            duration = 1.0
        }
        
        let sampleCount = Int(duration * Double(sampleRate))
        var samples: [Float] = []
        
        // Generate a simple sine wave pattern (mock audio)
        for i in 0..<sampleCount {
            let time = Double(i) / Double(sampleRate)
            let frequency: Double = 440.0 // A4 note
            let sample = sin(2.0 * Double.pi * frequency * time) * 0.3
            samples.append(Float(sample))
        }
        
        return samples
    }
    
    private func simulateAudioRecording(with audioData: [Float]) {
        let chunkSize = 1024 // Simulate processing in chunks
        let totalChunks = (audioData.count + chunkSize - 1) / chunkSize
        var currentChunk = 0
        
        simulateRecordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.isRecording else { return }
            
            let startIndex = currentChunk * chunkSize
            let endIndex = min(startIndex + chunkSize, audioData.count)
            
            if startIndex < audioData.count {
                let chunkData = Array(audioData[startIndex..<endIndex])
                self.testAudioData.append(contentsOf: chunkData)
                
                // Simulate audio buffer callback for live transcription
                if let buffer = self.createMockAudioBuffer(from: chunkData) {
                    self.onAudioBuffer?(buffer)
                }
                
                currentChunk += 1
            } else {
                // Recording complete
                self.simulateRecordingTimer?.invalidate()
            }
        }
    }
    
    private func createMockAudioBuffer(from samples: [Float]) -> AVAudioPCMBuffer? {
        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        )
        
        guard let audioFormat = format,
              let buffer = AVAudioPCMBuffer(
                pcmFormat: audioFormat,
                frameCapacity: AVAudioFrameCount(samples.count)
              ) else { return nil }
        
        buffer.frameLength = buffer.frameCapacity
        
        if let channelData = buffer.floatChannelData {
            channelData[0].update(from: samples, count: samples.count)
        }
        
        return buffer
    }
    
    private func createMockRecordingFile() {
        // Create a temporary file URL for the mock recording
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "mock_recording_\(Date().timeIntervalSince1970).wav"
        recordedFileURL = tempDir.appendingPathComponent(fileName)
        
        // In a real test, you might actually write a valid audio file
        // For now, we'll just create an empty file
        try? Data().write(to: recordedFileURL!)
    }
}