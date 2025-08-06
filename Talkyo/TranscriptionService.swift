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
    @Published private(set) var furiganaTokens: [FuriganaToken] = []
    @Published private(set) var transcriptionTime = ""
    @Published private(set) var isTranscribing = false
    @Published private(set) var hasRecording = false
    
    // MARK: - Dependencies
    
    private let speechRecognizer = SpeechRecognizer()
    private let audioRecorder = AudioRecorder()
    
    // MARK: - Private Properties
    
    private var transcriptionMode: TranscriptionMode = .standard
    
    // MARK: - Initialization
    
    init() {
        setupObservers()
        setupSpeechRecognizerCallbacks()
    }
    
    // MARK: - Public Methods
    
    func setRecognitionMode(_ mode: SpeechRecognitionMode) {
        clearTranscription()
        speechRecognizer.setConfiguration(mode)
    }
    
    func setTranscriptionMode(_ mode: TranscriptionMode) {
        transcriptionMode = mode
        clearTranscription()
    }
    
    func startRecording() {
        clearTranscription()
        
        if transcriptionMode == .live {
            setupLiveTranscription()
        }
        
        audioRecorder.startRecording()
    }
    
    func stopRecording() {
        if transcriptionMode == .live {
            teardownLiveTranscription()
        }
        
        Task {
            await processRecording()
        }
    }
    
    func playRecording() {
        audioRecorder.playRecording()
    }
    
    func cancelRecording() {
        if transcriptionMode == .live {
            teardownLiveTranscription()
        }
        
        audioRecorder.cancelRecording()
        clearTranscription()
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        audioRecorder.$hasRecording
            .receive(on: DispatchQueue.main)
            .assign(to: &$hasRecording)
    }
    
    private func setupSpeechRecognizerCallbacks() {
        speechRecognizer.onPartialTranscription = { [weak self] partialText in
            Task { @MainActor [weak self] in
                self?.updateTranscription(with: partialText, isFinal: false)
            }
        }
        
        speechRecognizer.onFinalTranscription = { [weak self] result in
            Task { @MainActor [weak self] in
                self?.updateTranscription(with: result.text, isFinal: true, mode: result.recognitionMode)
            }
        }
    }
    
    private func clearTranscription() {
        transcribedText = ""
        furiganaTokens = []
        transcriptionTime = ""
    }
    
    private func setupLiveTranscription() {
        audioRecorder.onAudioBuffer = { [weak self] buffer in
            self?.speechRecognizer.appendAudioBuffer(buffer)
        }
        
        do {
            try speechRecognizer.startLiveTranscription()
        } catch {
            print("Failed to start live transcription: \(error)")
        }
    }
    
    private func teardownLiveTranscription() {
        speechRecognizer.stopLiveTranscription()
        audioRecorder.onAudioBuffer = nil
    }
    
    private func processRecording() async {
        let audioData = audioRecorder.stopRecording()
        
        print("TranscriptionService: Processing recording with \(audioData.count) samples")
        
        guard !audioData.isEmpty,
              let recordingURL = audioRecorder.recordedFileURL else {
            print("TranscriptionService: No audio data or URL")
            transcribedText = "No audio recorded"
            return
        }
        
        print("TranscriptionService: Recording URL: \(recordingURL), mode: \(transcriptionMode)")
        
        // Only transcribe if in standard mode (live mode already transcribed)
        if transcriptionMode == .standard {
            print("TranscriptionService: Starting standard transcription")
            await transcribeAudio(from: recordingURL)
        } else {
            print("TranscriptionService: Skipping transcription (live mode)")
        }
    }
    
    private func transcribeAudio(from url: URL) async {
        isTranscribing = true
        defer { isTranscribing = false }
        
        let startTime = Date()
        
        print("TranscriptionService: Calling speechRecognizer.transcribe")
        
        do {
            let result = try await speechRecognizer.transcribe(audioURL: url)
            let elapsedTime = Date().timeIntervalSince(startTime)
            
            print("TranscriptionService: Transcription result: '\(result.text)'")
            
            updateTranscription(
                text: result.text,
                mode: result.recognitionMode,
                elapsedTime: elapsedTime
            )
        } catch {
            print("TranscriptionService: Transcription error: \(error)")
            handleTranscriptionError(error)
        }
    }
    
    private func updateTranscription(text: String, mode: String, elapsedTime: TimeInterval) {
        updateTranscription(with: text, isFinal: true, mode: mode, elapsedTime: elapsedTime)
    }
    
    private func updateTranscription(with text: String, isFinal: Bool, mode: String? = nil, elapsedTime: TimeInterval? = nil) {
        transcribedText = text
        furiganaTokens = FuriganaGenerator.generateTokens(for: text)
        
        if isFinal {
            if let elapsedTime = elapsedTime, let mode = mode {
                transcriptionTime = formatTranscriptionTime(elapsedTime, mode: mode)
            } else if let mode = mode {
                transcriptionTime = "Live - \(mode)"
            }
        }
    }
    
    private func handleTranscriptionError(_ error: Error) {
        transcribedText = "Error: \(error.localizedDescription)"
        furiganaTokens = []
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