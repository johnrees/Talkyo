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
    
    private let coreMLModel = CoreMLModelHandler()
    private let audioRecorder = AudioRecorder()
    
    var isModelReady: Bool {
        return coreMLModel.isModelLoaded
    }
    
    var modelStatus: String {
        return coreMLModel.modelStatus
    }
    
    var hasRecording: Bool {
        audioRecorder.hasRecording
    }
    
    var recordedFileURL: URL? {
        audioRecorder.recordedFileURL
    }
    
    func setCoreMLConfiguration(_ config: CoreMLConfiguration) {
        clearTranscription()
        coreMLModel.setConfiguration(config)
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
    
    func showTestText() {
        transcribedText = "あなたは日本人ですか"
        furiganaText = "あなたは 日本人(にほんじん) ですか"
        transcriptionTime = "Test (Ruby Text Demo)"
    }
    
    private func clearTranscription() {
        transcribedText = ""
        furiganaText = ""
        transcriptionTime = ""
    }
    
    private func transcribe(audioData: [Float]) async {
        isTranscribing = true
        let startTime = Date()
        
        var result: String?
        var error: String?
        
        if let url = recordedFileURL {
            let response = await coreMLModel.transcribe(audioURL: url)
            result = response.text
            error = response.error
        } else {
            error = "No recorded file URL available"
        }
        
        if let result = result {
            let elapsedMs = Int(Date().timeIntervalSince(startTime) * 1000)
            
            transcribedText = result
            furiganaText = FuriganaGenerator.generate(for: result)
            transcriptionTime = "\(elapsedMs)ms (\(coreMLModel.currentConfiguration.rawValue))"
        } else {
            transcribedText = error ?? "Transcription failed"
            furiganaText = ""
            transcriptionTime = ""
        }
        
        isTranscribing = false
    }
}