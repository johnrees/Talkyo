import Foundation
import Speech
import AVFoundation
import Observation

enum SpeechRecognitionError: LocalizedError {
    case recognizerUnavailable
    case recognitionFailed(String)
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .recognizerUnavailable:
            return "Speech recognizer is not available"
        case .recognitionFailed(let message):
            return "Recognition failed: \(message)"
        case .permissionDenied:
            return "Speech recognition permission denied"
        }
    }
}

@MainActor
@Observable
final class SpeechRecognizer: NSObject {
    private(set) var isAvailable = false
    private(set) var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    private var recognizer: SFSpeechRecognizer?
    private var currentConfiguration = SpeechRecognitionMode.onDevice
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioBufferRequest: SFSpeechAudioBufferRecognitionRequest?
    
    var onPartialTranscription: ((String) -> Void)?
    var onFinalTranscription: ((SpeechRecognitionResult) -> Void)?
    
    private let locale = Locale(identifier: "ja-JP")
    override init() {
        super.init()
        setupRecognizer()
        Task {
            await requestAuthorization()
        }
    }
    func setConfiguration(_ mode: SpeechRecognitionMode) {
        currentConfiguration = mode
    }
    func transcribe(audioURL: URL) async throws -> SpeechRecognitionResult {
        guard let recognizer = recognizer else {
            throw SpeechRecognitionError.recognizerUnavailable
        }
        
        guard recognizer.isAvailable else {
            throw SpeechRecognitionError.recognizerUnavailable
        }
        
        let request = createRecognitionRequest(for: audioURL)
        
        do {
            let result = try await performRecognition(with: request, using: recognizer)
            return SpeechRecognitionResult(
                text: result.bestTranscription.formattedString,
                recognitionMode: currentConfiguration.rawValue
            )
        } catch {
            throw SpeechRecognitionError.recognitionFailed(error.localizedDescription)
        }
    }
    func startLiveTranscription() throws {
        guard let recognizer = recognizer else {
            throw SpeechRecognitionError.recognizerUnavailable
        }
        
        guard recognizer.isAvailable else {
            throw SpeechRecognitionError.recognizerUnavailable
        }
        
        stopLiveTranscription()
        
        audioBufferRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let request = audioBufferRequest else { return }
        
        request.shouldReportPartialResults = true
        request.addsPunctuation = true
        request.taskHint = .dictation
        
        configureRecognitionMode(for: request)
        
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                if let error = error {
                    print("Live recognition error: \(error)")
                    self?.stopLiveTranscription()
                    return
                }
                
                if let result = result {
                    let transcription = result.bestTranscription.formattedString
                    
                    if result.isFinal {
                        self?.onFinalTranscription?(SpeechRecognitionResult(
                            text: transcription,
                            recognitionMode: self?.currentConfiguration.rawValue ?? ""
                        ))
                    } else {
                        self?.onPartialTranscription?(transcription)
                    }
                }
            }
        }
    }
    func stopLiveTranscription() {
        recognitionTask?.cancel()
        recognitionTask = nil
        audioBufferRequest?.endAudio()
        audioBufferRequest = nil
    }
    func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        audioBufferRequest?.append(buffer)
    }
    private func setupRecognizer() {
        recognizer = SFSpeechRecognizer(locale: locale)
        recognizer?.delegate = self
    }
    private func requestAuthorization() async {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                Task { @MainActor in
                    self?.authorizationStatus = status
                    self?.isAvailable = status == .authorized
                    continuation.resume()
                }
            }
        }
    }
    private func createRecognitionRequest(for url: URL) -> SFSpeechURLRecognitionRequest {
        let request = SFSpeechURLRecognitionRequest(url: url)
        
        request.shouldReportPartialResults = false
        request.addsPunctuation = true
        request.taskHint = .dictation
        
        configureRecognitionMode(for: request)
        
        return request
    }
    private func configureRecognitionMode(for request: SFSpeechRecognitionRequest) {
        switch currentConfiguration {
        case .onDevice:
            request.requiresOnDeviceRecognition = true
        case .server:
            request.requiresOnDeviceRecognition = false
        case .hybrid:
            break
        }
    }
    private func performRecognition(
        with request: SFSpeechURLRecognitionRequest,
        using recognizer: SFSpeechRecognizer
    ) async throws -> SFSpeechRecognitionResult {
        try await withCheckedThrowingContinuation { continuation in
            let task = recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if let result = result, result.isFinal {
                    continuation.resume(returning: result)
                }
            }
            _ = task
        }
    }
}

extension SpeechRecognizer: SFSpeechRecognizerDelegate {
    nonisolated func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        Task { @MainActor in
            self.isAvailable = available
        }
    }
}