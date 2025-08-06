//
//  TranscriptionServiceIntegrationTests.swift
//  TalkyoTests  
//
//  Integration tests for TranscriptionService with mocked dependencies
//

import XCTest
@testable import Talkyo

@MainActor
final class TranscriptionServiceIntegrationTests: XCTestCase {
    
    var transcriptionService: TranscriptionService!
    var mockAudioRecorder: MockAudioRecorder!
    
    override func setUpWithError() throws {
        mockAudioRecorder = MockAudioRecorder()
        transcriptionService = TranscriptionService(audioRecorder: mockAudioRecorder)
    }
    
    override func tearDownWithError() throws {
        transcriptionService = nil
        mockAudioRecorder = nil
    }
    
    func testStandardModeTranscriptionWorkflow() throws {
        // Set up test audio
        mockAudioRecorder.loadTestAudio(named: "konnichiwa.wav", expectedTranscription: "こんにちは")
        
        // Set to standard mode
        transcriptionService.setTranscriptionMode(.standard)
        
        // Start recording
        transcriptionService.startRecording()
        XCTAssertTrue(mockAudioRecorder.isRecording, "Mock recorder should be recording")
        
        // Simulate recording completion
        let expectation = XCTestExpectation(description: "Transcription completion")
        
        // Monitor transcription state
        let cancellable = transcriptionService.$transcribedText
            .sink { transcribedText in
                if !transcribedText.isEmpty && transcribedText != "" {
                    expectation.fulfill()
                }
            }
        
        // Stop recording (this triggers transcription)
        transcriptionService.stopRecording()
        
        // Wait for transcription to complete
        wait(for: [expectation], timeout: 10.0)
        
        // Verify results
        XCTAssertFalse(mockAudioRecorder.isRecording, "Should not be recording after stop")
        XCTAssertTrue(mockAudioRecorder.hasRecording, "Should have recording")
        XCTAssertFalse(transcriptionService.transcribedText.isEmpty, "Should have transcribed text")
        
        cancellable.cancel()
    }
    
    func testLiveModeTranscriptionWorkflow() throws {
        // Set up test audio
        mockAudioRecorder.loadTestAudio(named: "arigatou.wav", expectedTranscription: "ありがとうございます")
        
        // Set to live mode
        transcriptionService.setTranscriptionMode(.live)
        
        // Verify callback is set up for live transcription
        XCTAssertNotNil(mockAudioRecorder.onAudioBuffer, "Audio buffer callback should be set for live mode")
        
        // Start recording
        transcriptionService.startRecording()
        XCTAssertTrue(mockAudioRecorder.isRecording, "Mock recorder should be recording in live mode")
        
        // In live mode, transcription should start immediately with audio buffers
        let expectation = XCTestExpectation(description: "Live transcription")
        
        let cancellable = transcriptionService.$transcribedText
            .sink { transcribedText in
                if !transcribedText.isEmpty {
                    expectation.fulfill()
                }
            }
        
        // Stop recording
        transcriptionService.stopRecording()
        
        wait(for: [expectation], timeout: 10.0)
        
        // Verify live transcription results
        XCTAssertFalse(transcriptionService.transcribedText.isEmpty, "Should have live transcribed text")
        XCTAssertNil(mockAudioRecorder.onAudioBuffer, "Audio buffer callback should be cleared after live mode")
        
        cancellable.cancel()
    }
    
    func testCancelRecordingWorkflow() throws {
        mockAudioRecorder.loadTestAudio(named: "test.wav", expectedTranscription: "test")
        
        transcriptionService.startRecording()
        XCTAssertTrue(mockAudioRecorder.isRecording)
        
        // Cancel recording
        transcriptionService.cancelRecording()
        
        // Verify state is reset
        XCTAssertFalse(mockAudioRecorder.isRecording, "Should not be recording after cancel")
        XCTAssertFalse(mockAudioRecorder.hasRecording, "Should not have recording after cancel")
        XCTAssertTrue(transcriptionService.transcribedText.isEmpty, "Transcribed text should be cleared")
        XCTAssertTrue(transcriptionService.furiganaTokens.isEmpty, "Furigana tokens should be cleared")
    }
    
    func testRecognitionModeChanges() throws {
        let modes: [SpeechRecognitionMode] = [.onDevice, .server, .hybrid]
        
        for mode in modes {
            transcriptionService.setRecognitionMode(mode)
            
            // Verify text is cleared when changing modes
            XCTAssertTrue(transcriptionService.transcribedText.isEmpty, "Text should be cleared when changing recognition mode to \(mode)")
        }
    }
    
    func testPlayRecordingAfterTranscription() throws {
        mockAudioRecorder.loadTestAudio(named: "konnichiwa.wav", expectedTranscription: "こんにちは")
        
        // Record and transcribe
        transcriptionService.startRecording()
        transcriptionService.stopRecording()
        
        // Should be able to play recording
        XCTAssertNoThrow(transcriptionService.playRecording(), "Should be able to play recording without error")
    }
    
    func testFuriganaGeneration() throws {
        mockAudioRecorder.loadTestAudio(named: "library.wav", expectedTranscription: "図書館で本を読んでいます")
        
        let expectation = XCTestExpectation(description: "Furigana generation")
        
        let cancellable = transcriptionService.$furiganaTokens
            .sink { tokens in
                if !tokens.isEmpty {
                    expectation.fulfill()
                }
            }
        
        transcriptionService.startRecording()
        transcriptionService.stopRecording()
        
        wait(for: [expectation], timeout: 10.0)
        
        // Verify furigana tokens are generated
        XCTAssertFalse(transcriptionService.furiganaTokens.isEmpty, "Should have generated furigana tokens")
        
        // Check that some tokens need furigana (contain kanji)
        let tokensNeedingFurigana = transcriptionService.furiganaTokens.filter { $0.needsFurigana }
        XCTAssertFalse(tokensNeedingFurigana.isEmpty, "Should have tokens that need furigana for kanji text")
        
        cancellable.cancel()
    }
    
    func testTranscriptionTimeRecording() throws {
        mockAudioRecorder.loadTestAudio(named: "konnichiwa.wav", expectedTranscription: "こんにちは")
        
        let expectation = XCTestExpectation(description: "Transcription time recording")
        
        let cancellable = transcriptionService.$transcriptionTime
            .sink { timeString in
                if !timeString.isEmpty && timeString.contains("ms") {
                    expectation.fulfill()
                }
            }
        
        transcriptionService.startRecording()
        transcriptionService.stopRecording()
        
        wait(for: [expectation], timeout: 10.0)
        
        // Verify transcription time is recorded
        XCTAssertFalse(transcriptionService.transcriptionTime.isEmpty, "Should have transcription time")
        XCTAssertTrue(transcriptionService.transcriptionTime.contains("ms"), "Time should be in milliseconds")
        
        cancellable.cancel()
    }
}