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
        
        // Apply configuration mode
        configureRecognitionMode(for: request)
        
        return request
    }
    
    private func configureRecognitionMode(for request: SFSpeechURLRecognitionRequest) {
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