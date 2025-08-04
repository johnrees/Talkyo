//
//  WhisperModelHandler.swift
//  Talkyo
//
//  Created by John Rees on 8/2/25.
//

import Foundation
import AVFoundation
import WhisperKit

class WhisperModelHandler: ObservableObject {
    private var whisperKit: WhisperKit?
    @Published var isModelLoaded = false
    @Published var modelLoadingProgress: Double = 0.0
    @Published var modelLoadingStatus = "Initializing..."
    
    init() {
        Task {
            await loadModel()
        }
    }
    
    private func loadModel() async {
        print("Starting WhisperKit model loading...")
        
        await MainActor.run {
            self.modelLoadingStatus = "Downloading Whisper model..."
        }
        
        do {
            // Start with tiny model for faster testing
            // Options: "tiny", "tiny.en", "base", "base.en", "small", "medium", "large-v3"
            print("Attempting to load WhisperKit with tiny model...")
            whisperKit = try await WhisperKit(model: "tiny", verbose: true)
            
            await MainActor.run {
                self.isModelLoaded = true
                self.modelLoadingStatus = "Model loaded successfully"
            }
            
            print("✅ WhisperKit loaded successfully with tiny model")
        } catch {
            print("❌ Failed to load WhisperKit: \(error)")
            print("Error details: \(error.localizedDescription)")
            
            await MainActor.run {
                self.modelLoadingStatus = "Failed to load model: \(error.localizedDescription)"
            }
        }
    }
    
    func transcribe(audioData: [Float]) async -> String? {
        guard let whisperKit = whisperKit else {
            print("WhisperKit not loaded")
            return nil
        }
        
        do {
            // Convert Float array to AVAudioPCMBuffer for WhisperKit
            guard let buffer = createAudioBuffer(from: audioData) else {
                print("Failed to create audio buffer")
                return nil
            }
            
            // Transcribe with Japanese language - optimized options
            let results = try await whisperKit.transcribe(
                audioArray: audioData,
                decodeOptions: DecodingOptions(
                    task: .transcribe,  // Not translate
                    language: "ja",  // Force Japanese
                    temperatureFallbackCount: 3,  // Try multiple temperatures for better accuracy
                    sampleLength: 224,  // Optimal for Japanese
                    topK: 5,
                    usePrefillPrompt: true,
                    usePrefillCache: true,
                    skipSpecialTokens: true,
                    withoutTimestamps: true
                )
            )
            
            // Combine all segments into one text
            return results.map { $0.text }.joined(separator: " ")
        } catch {
            print("Transcription error: \(error)")
            return nil
        }
    }
    
    private func createAudioBuffer(from samples: [Float]) -> AVAudioPCMBuffer? {
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                  sampleRate: 16000,
                                  channels: 1,
                                  interleaved: false)!
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                           frameCapacity: AVAudioFrameCount(samples.count)) else {
            return nil
        }
        
        buffer.frameLength = buffer.frameCapacity
        
        if let channelData = buffer.floatChannelData {
            channelData[0].update(from: samples, count: samples.count)
        }
        
        return buffer
    }
}