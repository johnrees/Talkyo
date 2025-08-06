//
//  TestAudioManager.swift
//  TalkyoTests
//
//  Manages test audio files and metadata
//

import Foundation

struct TestAudioManager {
    
    struct TestAudioFile {
        let filename: String
        let text: String
        let expectedTranscription: String
        let fileURL: URL?
    }
    
    private static let testAudioDirectory = "TalkyoTests/TestAudio"
    
    static func loadTestAudioMetadata() -> [TestAudioFile] {
        guard let metadataURL = Bundle.main.url(forResource: "test_metadata", withExtension: "json", subdirectory: testAudioDirectory),
              let data = try? Data(contentsOf: metadataURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let testFiles = json["test_audio_files"] as? [[String: String]] else {
            print("Failed to load test audio metadata")
            return []
        }
        
        return testFiles.compactMap { fileData in
            guard let filename = fileData["filename"],
                  let text = fileData["text"],
                  let expectedTranscription = fileData["expected_transcription"] else {
                return nil
            }
            
            let fileURL = Bundle.main.url(forResource: String(filename.dropLast(4)), withExtension: "wav", subdirectory: testAudioDirectory)
            
            return TestAudioFile(
                filename: filename,
                text: text,
                expectedTranscription: expectedTranscription,
                fileURL: fileURL
            )
        }
    }
    
    static func getTestAudio(named filename: String) -> TestAudioFile? {
        return loadTestAudioMetadata().first { $0.filename == filename }
    }
}

// MARK: - Test Audio Assets

enum TestAudioAssets {
    static let basicGreetings = [
        "konnichiwa.wav": "こんにちは",
        "arigatou.wav": "ありがとうございます", 
        "sayounara.wav": "さようなら"
    ]
    
    static let complexSentences = [
        "weather.wav": "今日は良い天気ですね",
        "library.wav": "図書館で本を読んでいます"
    ]
    
    static let allTestFiles = basicGreetings.merging(complexSentences) { current, _ in current }
}