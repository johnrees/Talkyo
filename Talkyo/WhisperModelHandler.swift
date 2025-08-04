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
    
    init() {
        Task {
            await loadModel()
        }
    }
    
    private func loadModel() async {
        modelStatus = "Downloading model..."
        
        do {
            whisperKit = try await WhisperKit(model: "tiny", verbose: true)
            isModelLoaded = true
            modelStatus = "Ready"
            print("✅ WhisperKit loaded successfully")
        } catch {
            modelStatus = "Failed: \(error.localizedDescription)"
            print("❌ Failed to load WhisperKit: \(error)")
        }
    }
    
    func transcribe(audioData: [Float]) async -> String? {
        guard let whisperKit = whisperKit else {
            print("WhisperKit not loaded")
            return nil
        }
        
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
            
            return results.map { $0.text }.joined(separator: " ")
        } catch {
            print("Transcription error: \(error)")
            return nil
        }
    }
}