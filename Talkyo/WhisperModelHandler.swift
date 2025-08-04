//
//  WhisperModelHandler.swift
//  Talkyo
//
//  Created by John Rees on 8/2/25.
//

import Foundation
import WhisperKit

@MainActor
class WhisperModelHandler: ObservableObject {
    private var whisperKit: WhisperKit?
    @Published var isModelLoaded = false
    @Published var modelStatus = "Initializing..."
    @Published var currentModelSize: WhisperModelSize = .tiny
    
    init() {
        Task {
            await loadModel(size: .tiny)
        }
    }
    
    func loadModel(size: WhisperModelSize) async {
        // Don't reload if same model
        if size == currentModelSize && isModelLoaded {
            print("ℹ️ Model \(size.rawValue) already loaded")
            return
        }
        
        isModelLoaded = false
        modelStatus = "Loading \(size.displayName) model..."
        currentModelSize = size
        
        // Clear existing model
        whisperKit = nil
        
        do {
            print("📥 Loading Whisper model: \(size.rawValue)")
            whisperKit = try await WhisperKit(model: size.rawValue, verbose: true)
            isModelLoaded = true
            modelStatus = "Ready (\(size.displayName))"
            print("✅ WhisperKit \(size.rawValue) loaded successfully")
        } catch {
            modelStatus = "Failed: \(error.localizedDescription)"
            print("❌ Failed to load WhisperKit \(size.rawValue): \(error)")
        }
    }
    
    func transcribe(audioData: [Float]) async -> (text: String?, error: String?) {
        guard let whisperKit = whisperKit else {
            let error = "WhisperKit not loaded - model status: \(modelStatus)"
            print("❌ \(error)")
            return (nil, error)
        }
        
        print("📊 Whisper transcribe called with \(audioData.count) samples")
        
        do {
            let results = try await whisperKit.transcribe(
                audioArray: audioData,
                decodeOptions: DecodingOptions(
                    task: .transcribe,
                    language: "ja",
                    temperatureFallbackCount: 3,
                    sampleLength: 224,
                    topK: 5,
                    usePrefillPrompt: true,
                    usePrefillCache: true,
                    skipSpecialTokens: true,
                    withoutTimestamps: true
                )
            )
            
            let text = results.map { $0.text }.joined(separator: " ")
            print("✅ Whisper transcription successful: \(text)")
            return (text, nil)
        } catch {
            let errorMsg = "Whisper error: \(error.localizedDescription)"
            print("❌ \(errorMsg)")
            return (nil, errorMsg)
        }
    }
}