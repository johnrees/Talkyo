//
//  CoreMLModelHandler.swift
//  Talkyo
//
//  Created by John Rees on 8/2/25.
//

import Foundation
import Speech
import AVFoundation

@MainActor
class CoreMLModelHandler: ObservableObject {
    @Published var isModelLoaded = false
    @Published var modelStatus = "Initializing..."
    @Published var currentConfiguration = CoreMLConfiguration.onDevice
    
    private let speechRecognizer: SFSpeechRecognizer?
    
    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
        
        Task {
            await requestPermissions()
        }
    }
    
    private func requestPermissions() async {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                Task { @MainActor in
                    switch status {
                    case .authorized:
                        self.isModelLoaded = true
                        self.modelStatus = "Ready"
                        print("✅ Speech recognition authorized")
                    case .denied:
                        self.modelStatus = "Permission denied"
                        print("❌ Speech recognition denied")
                    case .restricted:
                        self.modelStatus = "Speech recognition restricted"
                        print("❌ Speech recognition restricted")
                    case .notDetermined:
                        self.modelStatus = "Permission not determined"
                        print("❌ Speech recognition not determined")
                    @unknown default:
                        self.modelStatus = "Unknown permission status"
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    func transcribe(audioURL: URL) async -> (text: String?, error: String?) {
        guard let recognizer = speechRecognizer else {
            let error = "Speech recognizer is nil"
            print("❌ \(error)")
            return (nil, error)
        }
        
        guard recognizer.isAvailable else {
            let error = "Speech recognizer not available - status: \(modelStatus)"
            print("❌ \(error)")
            return (nil, error)
        }
        
        print("📊 Core ML transcribe called with URL: \(audioURL.lastPathComponent)")
        
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false
        
        // Configure based on selected mode
        switch currentConfiguration {
        case .onDevice:
            request.requiresOnDeviceRecognition = true
        case .server:
            request.requiresOnDeviceRecognition = false
        case .hybrid:
            // Don't set requiresOnDeviceRecognition - let system decide
            break
        }
        
        print("📊 Core ML using \(currentConfiguration.rawValue) mode")
        
        do {
            let result: SFSpeechRecognitionResult = try await withCheckedThrowingContinuation { continuation in
                recognizer.recognitionTask(with: request) { result, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    if let result = result, result.isFinal {
                        continuation.resume(returning: result)
                    }
                }
            }
            
            let text = result.bestTranscription.formattedString
            print("✅ Core ML transcription successful: \(text)")
            return (text, nil)
        } catch {
            let errorMsg = "Core ML error: \(error.localizedDescription)"
            print("❌ \(errorMsg)")
            return (nil, errorMsg)
        }
    }
    
    func setConfiguration(_ config: CoreMLConfiguration) {
        currentConfiguration = config
        print("ℹ️ Core ML configuration changed to: \(config.rawValue)")
    }
}