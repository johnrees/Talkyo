import Foundation
import Observation

@MainActor
@Observable
final class TranscriptionService {
    private(set) var transcribedText = ""
    private(set) var furiganaTokens: [FuriganaToken] = []
    private(set) var transcriptionTime = ""
    private(set) var isTranscribing = false
    private(set) var hasRecording = false
    
    private let speechRecognizer = SpeechRecognizer()
    private let audioRecorder = AudioRecorder()
    private var transcriptionMode: TranscriptionMode = .standard
    
    init() {
        setupObservers()
        setupSpeechRecognizerCallbacks()
    }
    
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
    private func setupObservers() {
        Task { [weak self] in
            while true {
                self?.hasRecording = self?.audioRecorder.hasRecording ?? false
                try? await Task.sleep(nanoseconds: 100_000_000) // Check every 0.1s
            }
        }
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
        
        guard !audioData.isEmpty,
              let recordingURL = audioRecorder.recordedFileURL else {
            transcribedText = "No audio recorded"
            return
        }
        
        if transcriptionMode == .standard {
            await transcribeAudio(from: recordingURL)
        }
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

struct SpeechRecognitionResult: Sendable {
    let text: String
    let recognitionMode: String
}