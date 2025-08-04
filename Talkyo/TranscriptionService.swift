//
//  TranscriptionService.swift
//  Talkyo
//
//  Coordinates transcription workflow
//

import Foundation

@MainActor
class TranscriptionService: ObservableObject {
    @Published var transcribedText = ""
    @Published var furiganaText = ""
    @Published var transcriptionTime = ""
    @Published var isTranscribing = false
    
    private let whisperModel = WhisperModelHandler()
    private let audioRecorder = AudioRecorder()
    
    var isModelReady: Bool {
        whisperModel.isModelLoaded
    }
    
    var modelStatus: String {
        whisperModel.modelStatus
    }
    
    var hasRecording: Bool {
        audioRecorder.hasRecording
    }
    
    func startRecording() {
        clearTranscription()
        audioRecorder.startRecording()
    }
    
    func stopRecording() {
        let audioData = audioRecorder.stopRecording()
        
        if !audioData.isEmpty {
            Task {
                await transcribe(audioData: audioData)
            }
        }
    }
    
    func playRecording() {
        audioRecorder.playRecording()
    }
    
    private func clearTranscription() {
        transcribedText = ""
        furiganaText = ""
        transcriptionTime = ""
    }
    
    private func transcribe(audioData: [Float]) async {
        isTranscribing = true
        let startTime = Date()
        
        if let result = await whisperModel.transcribe(audioData: audioData) {
            let elapsedMs = Int(Date().timeIntervalSince(startTime) * 1000)
            
            transcribedText = result
            furiganaText = FuriganaGenerator.generate(for: result)
            transcriptionTime = "\(elapsedMs)ms"
        } else {
            transcribedText = "Transcription failed"
        }
        
        isTranscribing = false
    }
}