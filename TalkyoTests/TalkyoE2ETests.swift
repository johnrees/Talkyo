//
//  TalkyoE2ETests.swift  
//  TalkyoTests
//
//  End-to-end tests for Talkyo transcription workflow
//

import XCTest
@testable import Talkyo

@MainActor
final class TalkyoE2ETests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Complete Transcription Workflow Tests
    
    func testCompleteTranscriptionWorkflow_BasicGreeting() throws {
        // Verify initial state
        XCTAssertTrue(app.buttons["recordButton"].exists, "Record button should exist")
        
        let initialText = app.staticTexts["話してください"]
        XCTAssertTrue(initialText.waitForExistence(timeout: 2.0), "Initial placeholder text should be visible")
        
        // Load test audio in test mode
        loadTestAudio("konnichiwa.wav")
        
        // Perform recording interaction - hold button for duration
        let recordButton = app.buttons["recordButton"]
        recordButton.press(forDuration: 2.0)
        
        // Wait for transcription to complete
        let transcriptionText = app.staticTexts.matching(identifier: "transcriptionResult").firstMatch
        XCTAssertTrue(transcriptionText.waitForExistence(timeout: 10.0), "Transcription result should appear")
        
        // Verify expected transcription
        let expectedText = "こんにちは"
        XCTAssertTrue(transcriptionText.label.contains(expectedText), "Should contain expected Japanese text: '\(expectedText)', got: '\(transcriptionText.label)'")
        
        // Verify furigana display is present (check for FuriganaTextView)
        let furiganaView = app.otherElements.matching(identifier: "furiganaTextView").firstMatch
        XCTAssertTrue(furiganaView.exists, "Furigana text view should be present")
        
        // Verify playback button is available
        let playButton = app.buttons["playRecordingButton"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 2.0), "Play button should be available after recording")
        XCTAssertTrue(playButton.isEnabled, "Play button should be enabled")
        
        // Test playback functionality
        playButton.tap()
        
        // Verify transcription time is displayed
        let timeLabel = app.staticTexts.matching(identifier: "transcriptionTime").firstMatch
        XCTAssertTrue(timeLabel.exists, "Transcription time should be displayed")
        XCTAssertTrue(timeLabel.label.contains("ms"), "Time label should contain milliseconds")
    }
    
    func testCompleteTranscriptionWorkflow_LongSentence() throws {
        // Load complex sentence test audio
        loadTestAudio("weather.wav")
        
        let recordButton = app.buttons["recordButton"]
        recordButton.press(forDuration: 3.5)
        
        let transcriptionText = app.staticTexts.matching(identifier: "transcriptionResult").firstMatch
        XCTAssertTrue(transcriptionText.waitForExistence(timeout: 10.0))
        
        let expectedText = "今日は良い天気ですね"
        XCTAssertTrue(transcriptionText.label.contains(expectedText), "Should transcribe complex sentence correctly")
    }
    
    // MARK: - Live Mode Transcription Tests
    
    func testLiveModeTranscription() throws {
        // Switch to Live mode
        let transcriptionModeSegment = app.segmentedControls["transcriptionModeSelector"]
        XCTAssertTrue(transcriptionModeSegment.exists, "Transcription mode selector should exist")
        
        let liveButton = transcriptionModeSegment.buttons["Live"]
        liveButton.tap()
        
        // Load streaming test audio
        loadTestAudio("library.wav")
        
        // Start recording and verify live updates
        let recordButton = app.buttons["recordButton"]
        recordButton.press(forDuration: 4.0)
        
        // In live mode, we should see partial results during recording
        let partialText = app.staticTexts.matching(identifier: "transcriptionResult").firstMatch
        
        // Wait a bit and check if text appears during recording (live updates)
        let exists = partialText.waitForExistence(timeout: 3.0)
        XCTAssertTrue(exists, "Partial transcription should appear during live recording")
        
        // Final verification after recording ends
        let expectedFinalText = "図書館で本を読んでいます"
        XCTAssertTrue(partialText.label.contains(expectedFinalText), "Should show final transcription result")
    }
    
    // MARK: - Swipe to Cancel Functionality
    
    func testSwipeToCancelFunctionality() throws {
        loadTestAudio("konnichiwa.wav")
        
        let recordButton = app.buttons["recordButton"]
        
        // Start recording then swipe to cancel
        recordButton.press(forDuration: 0.5)
        recordButton.swipeUp()
        
        // Verify no transcription occurred
        let transcriptionResult = app.staticTexts.matching(identifier: "transcriptionResult").firstMatch
        XCTAssertFalse(transcriptionResult.exists, "No transcription should appear after cancel")
        
        // Verify back to initial state
        let placeholderText = app.staticTexts["話してください"]
        XCTAssertTrue(placeholderText.exists, "Should return to initial placeholder text")
        
        // Verify play button is not available
        let playButton = app.buttons["playRecordingButton"]
        XCTAssertFalse(playButton.exists || playButton.isEnabled, "Play button should not be available after cancel")
    }
    
    // MARK: - Recognition Mode Tests
    
    func testDifferentRecognitionModes() throws {
        let recognitionModeSegment = app.segmentedControls["recognitionModeSelector"]
        XCTAssertTrue(recognitionModeSegment.exists, "Recognition mode selector should exist")
        
        let modes = ["On-Device", "Server", "Hybrid"]
        
        for mode in modes {
            // Switch to the specific mode
            recognitionModeSegment.buttons[mode].tap()
            
            // Load test audio
            loadTestAudio("arigatou.wav")
            
            // Perform transcription
            let recordButton = app.buttons["recordButton"]
            recordButton.press(forDuration: 2.5)
            
            // Verify transcription works in this mode
            let transcriptionText = app.staticTexts.matching(identifier: "transcriptionResult").firstMatch
            XCTAssertTrue(transcriptionText.waitForExistence(timeout: 10.0), "Transcription should work in \(mode) mode")
            
            let expectedText = "ありがとうございます"
            XCTAssertTrue(transcriptionText.label.contains(expectedText), "Should transcribe correctly in \(mode) mode")
            
            // Verify mode is shown in transcription time
            let timeLabel = app.staticTexts.matching(identifier: "transcriptionTime").firstMatch
            XCTAssertTrue(timeLabel.exists, "Time label should exist for \(mode) mode")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testEmptyRecordingHandling() throws {
        let recordButton = app.buttons["recordButton"]
        
        // Very quick tap (no audio)
        recordButton.tap()
        
        // Should handle empty recording gracefully
        let errorText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'No audio'")).firstMatch
        let placeholderText = app.staticTexts["話してください"]
        
        // Either show error message or return to placeholder
        XCTAssertTrue(errorText.exists || placeholderText.exists, "Should handle empty recording gracefully")
    }
    
    // MARK: - UI State Tests
    
    func testUIStatesDuringRecording() throws {
        loadTestAudio("konnichiwa.wav")
        
        let recordButton = app.buttons["recordButton"]
        
        // Test initial state
        XCTAssertTrue(recordButton.exists && recordButton.isEnabled, "Record button should be enabled initially")
        
        // Start recording (simulated)
        recordButton.press(forDuration: 0.1)  // Brief press to start
        
        // During recording, button state should change (if implemented)
        // This depends on your UI implementation
        
        // Complete the recording
        recordButton.press(forDuration: 2.0)
        
        // After recording, verify final state
        let playButton = app.buttons["playRecordingButton"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 3.0), "Play button should appear after successful recording")
    }
    
    // MARK: - Helper Methods
    
    private func loadTestAudio(_ filename: String) {
        // In UI testing, we need to signal the app to load specific test audio
        // This would be implemented through launch arguments or test-specific UI elements
        
        if app.buttons["loadTestAudioButton"].exists {
            app.buttons["loadTestAudioButton"].tap()
            
            // Select specific audio file
            let audioButton = app.buttons[filename.replacingOccurrences(of: ".wav", with: "")]
            if audioButton.exists {
                audioButton.tap()
            }
        }
        
        // Alternative: Use launch environment to pre-configure test audio
        // This would be set in setUpWithError() method
    }
}

// MARK: - Test Utilities

extension TalkyoE2ETests {
    
    private func verifyTranscriptionQuality(_ actual: String, expected: String, tolerance: Double = 0.8) -> Bool {
        // Simple similarity check for speech recognition variations
        let actualClean = actual.trimmingCharacters(in: .whitespacesAndNewlines)
        let expectedClean = expected.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // For exact match testing with controlled audio
        return actualClean.contains(expectedClean) || expectedClean.contains(actualClean)
    }
    
    private func waitForTranscriptionCompletion(timeout: TimeInterval = 10.0) -> XCUIElement? {
        let transcriptionResult = app.staticTexts.matching(identifier: "transcriptionResult").firstMatch
        
        if transcriptionResult.waitForExistence(timeout: timeout) {
            return transcriptionResult
        }
        
        return nil
    }
}