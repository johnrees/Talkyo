//
//  TranscriptionService.swift
//  Talkyo
//
//  Coordinates transcription workflow
//

import Foundation
import Combine

// MARK: - Transcription Service

@MainActor
final class TranscriptionService: ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var transcribedText = ""
    @Published private(set) var furiganaText = ""
    @Published private(set) var transcriptionTime = ""
    @Published private(set) var isTranscribing = false
    @Published private(set) var hasRecording = false
    
    // MARK: - Dependencies
    
    private let speechRecognizer = SpeechRecognizer()
    private let audioRecorder = AudioRecorder()
    
    // MARK: - Private Properties
    
    private var recordingURL: URL? {
        audioRecorder.recordedFileURL
    }
    
    // MARK: - Initialization
    
    init() {
        setupObservers()
    }
    
    // MARK: - Public Methods
    
    func setRecognitionMode(_ mode: SpeechRecognitionMode) {
        clearTranscription()
        speechRecognizer.setConfiguration(mode)
    }
    
    func startRecording() {
        clearTranscription()
        audioRecorder.startRecording()
    }
    
    func stopRecording() {
        Task {
            await processRecording()
        }
    }
    
    func playRecording() {
        audioRecorder.playRecording()
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        audioRecorder.$hasRecording
            .receive(on: DispatchQueue.main)
            .assign(to: &$hasRecording)
    }
    
    private func clearTranscription() {
        transcribedText = ""
        furiganaText = ""
        transcriptionTime = ""
    }
    
    private func processRecording() async {
        let audioData = audioRecorder.stopRecording()
        
        guard !audioData.isEmpty,
              let recordingURL = recordingURL else {
            transcribedText = "No audio recorded"
            return
        }
        
        await transcribeAudio(from: recordingURL)
    }
    
    private func transcribeAudio(from url: URL) async {
        isTranscribing = true
        defer { isTranscribing = false }
        
        let startTime = Date()
        
        do {
            let result = try await speechRecognizer.transcribe(audioURL: url)
            let elapsedTime = Date().timeIntervalSince(startTime)
            
            updateTranscription(
                text: result.text,
                mode: result.recognitionMode,
                elapsedTime: elapsedTime
            )
        } catch {
            handleTranscriptionError(error)
        }
    }
    
    private func updateTranscription(text: String, mode: String, elapsedTime: TimeInterval) {
        transcribedText = text
        furiganaText = FuriganaGenerator.generate(for: text)
        transcriptionTime = formatTranscriptionTime(elapsedTime, mode: mode)
    }
    
    private func handleTranscriptionError(_ error: Error) {
        transcribedText = "Error: \(error.localizedDescription)"
        furiganaText = ""
        transcriptionTime = ""
    }
    
    private func formatTranscriptionTime(_ interval: TimeInterval, mode: String) -> String {
        let milliseconds = Int(interval * 1000)
        return "\(milliseconds)ms (\(mode))"
    }
}

// MARK: - Speech Recognition Result

struct SpeechRecognitionResult {
    let text: String
    let recognitionMode: String
}