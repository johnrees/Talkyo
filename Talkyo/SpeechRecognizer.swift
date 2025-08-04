//
//  SpeechRecognizer.swift
//  Talkyo
//
//  Handles speech recognition using Apple's Speech framework
//

import Foundation
import Speech
import AVFoundation

// MARK: - Speech Recognition Error

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

// MARK: - Speech Recognizer

@MainActor
final class SpeechRecognizer: NSObject, ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var isAvailable = false
    @Published private(set) var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    // MARK: - Private Properties
    
    private var recognizer: SFSpeechRecognizer?
    private var currentConfiguration = SpeechRecognitionMode.onDevice
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioBufferRequest: SFSpeechAudioBufferRecognitionRequest?
    
    // MARK: - Callbacks
    
    var onPartialTranscription: ((String) -> Void)?
    var onFinalTranscription: ((SpeechRecognitionResult) -> Void)?
    
    // MARK: - Constants
    
    private let locale = Locale(identifier: "ja-JP")
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupRecognizer()
        Task {
            await requestAuthorization()
        }
    }
    
    // MARK: - Public Methods
    
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
        
        // Cancel any existing task
        stopLiveTranscription()
        
        // Create and configure the request
        audioBufferRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let request = audioBufferRequest else { return }
        
        request.shouldReportPartialResults = true
        
        // Enable punctuation for iOS 16+
        if #available(iOS 16.0, *) {
            request.addsPunctuation = true
            request.taskHint = .dictation
        }
        
        // Configure recognition mode
        configureRecognitionMode(for: request)
        
        // Start the recognition task
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
    
    // MARK: - Private Methods
    
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
        
        // Configure request settings
        request.shouldReportPartialResults = false
        
        // Enable punctuation for iOS 16+
        if #available(iOS 16.0, *) {
            request.addsPunctuation = true
            request.taskHint = .dictation
        }
        
        // Additional settings for iOS 18+
        if #available(iOS 18.0, *) {
            // Ensure punctuation is enabled for iOS 18
            request.addsPunctuation = true
        }
        
        // Apply configuration mode
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
            // Let the system decide
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
            
            // Store task reference if needed for cancellation
            _ = task
        }
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension SpeechRecognizer: SFSpeechRecognizerDelegate {
    nonisolated func speechRecognizer(
        _ speechRecognizer: SFSpeechRecognizer,
        availabilityDidChange available: Bool
    ) {
        Task { @MainActor in
            self.isAvailable = available
        }
    }
}