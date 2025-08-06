//
//  MockAudioRecorderTests.swift
//  TalkyoTests
//
//  Unit tests for MockAudioRecorder
//

import XCTest
@testable import Talkyo

@MainActor
final class MockAudioRecorderTests: XCTestCase {
    
    var mockRecorder: MockAudioRecorder!
    
    override func setUpWithError() throws {
        mockRecorder = MockAudioRecorder()
    }
    
    override func tearDownWithError() throws {
        mockRecorder = nil
    }
    
    func testInitialState() throws {
        XCTAssertFalse(mockRecorder.isRecording, "Should not be recording initially")
        XCTAssertFalse(mockRecorder.hasRecording, "Should not have recording initially")
        XCTAssertNil(mockRecorder.recordedFileURL, "Should not have file URL initially")
    }
    
    func testLoadTestAudio() throws {
        mockRecorder.loadTestAudio(named: "konnichiwa.wav", expectedTranscription: "こんにちは")
        
        // Audio should be loaded but not recorded yet
        XCTAssertFalse(mockRecorder.isRecording, "Should not be recording after loading")
        XCTAssertFalse(mockRecorder.hasRecording, "Should not have recording after loading")
    }
    
    func testRecordingLifecycle() throws {
        mockRecorder.loadTestAudio(named: "test.wav", expectedTranscription: "test")
        
        // Start recording
        mockRecorder.startRecording()
        XCTAssertTrue(mockRecorder.isRecording, "Should be recording after start")
        XCTAssertFalse(mockRecorder.hasRecording, "Should not have completed recording yet")
        
        // Stop recording
        let audioData = mockRecorder.stopRecording()
        XCTAssertFalse(mockRecorder.isRecording, "Should not be recording after stop")
        XCTAssertTrue(mockRecorder.hasRecording, "Should have recording after stop")
        XCTAssertFalse(audioData.isEmpty, "Should return audio data")
        XCTAssertNotNil(mockRecorder.recordedFileURL, "Should have file URL after recording")
    }
    
    func testCancelRecording() throws {
        mockRecorder.loadTestAudio(named: "test.wav", expectedTranscription: "test")
        
        // Start then cancel
        mockRecorder.startRecording()
        XCTAssertTrue(mockRecorder.isRecording)
        
        mockRecorder.cancelRecording()
        XCTAssertFalse(mockRecorder.isRecording, "Should not be recording after cancel")
        XCTAssertFalse(mockRecorder.hasRecording, "Should not have recording after cancel")
        XCTAssertNil(mockRecorder.recordedFileURL, "Should not have file URL after cancel")
    }
    
    func testAudioBufferCallback() throws {
        mockRecorder.loadTestAudio(named: "test.wav", expectedTranscription: "test")
        
        var callbackCount = 0
        mockRecorder.onAudioBuffer = { buffer in
            callbackCount += 1
            XCTAssertGreaterThan(buffer.frameLength, 0, "Buffer should have frames")
        }
        
        // Start recording and wait briefly for callbacks
        mockRecorder.startRecording()
        
        let expectation = XCTestExpectation(description: "Audio buffer callback")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        mockRecorder.stopRecording()
        
        XCTAssertGreaterThan(callbackCount, 0, "Should have received audio buffer callbacks")
    }
    
    func testPlayRecording() throws {
        mockRecorder.loadTestAudio(named: "test.wav", expectedTranscription: "test")
        
        // Should not crash when called without recording
        mockRecorder.playRecording()
        
        // Record first
        mockRecorder.startRecording()
        _ = mockRecorder.stopRecording()
        
        // Should not crash when called with recording
        mockRecorder.playRecording()
        XCTAssertTrue(mockRecorder.hasRecording, "Should still have recording after play")
    }
}