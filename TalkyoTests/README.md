# Talkyo E2E Testing Implementation

This directory contains the complete e2e testing implementation for Talkyo, including generated audio files, mock components, and comprehensive test suites.

## Overview

The testing implementation follows the architecture outlined in [GitHub Issue #3](https://github.com/johnrees/Talkyo/issues/3) and provides:

1. **Generated Japanese audio files** using ElevenLabs API
2. **Mock components** with dependency injection support  
3. **Comprehensive XCUITest suite** for end-to-end workflow testing
4. **Integration tests** using mocked dependencies

## Project Setup Required

To complete the testing setup, you need to add test targets to your Xcode project:

### 1. Add Test Targets

In Xcode:
1. Select your project in the navigator
2. Click the "+" button to add a new target
3. Choose "Unit Testing Bundle" → Create "TalkyoTests" 
4. Choose "UI Testing Bundle" → Create "TalkyoUITests"

### 2. Add Test Files to Targets

Add these files to the appropriate test targets:

**Unit Test Target (TalkyoTests):**
- `MockAudioRecorder.swift`
- `MockAudioRecorderTests.swift` 
- `TranscriptionServiceIntegrationTests.swift`
- `TestAudioManager.swift`
- `TestAudio/` directory with audio files

**UI Test Target (TalkyoUITests):**
- `TalkyoE2ETests.swift`

**Main Target Updates:**
- `AudioRecorderProtocol.swift` (already added to main target)
- Updated `TranscriptionService.swift` (dependency injection support)
- Updated `ContentView.swift` (accessibility identifiers + test mode)
- Updated `SettingsView.swift` (accessibility identifiers)

### 3. Generate Test Audio Files

The test audio files need to be generated using the ElevenLabs API. Run the generation script with your API key:

```bash
# Set your API key
export ELEVENLABS_API_KEY="your_api_key_here"

# Generate audio files (choose one method):
bash generate_audio.sh
# OR
node generate_test_audio.js  
# OR
python3 generate_test_audio.py
```

This creates:
- `TalkyoTests/TestAudio/konnichiwa.wav` ("こんにちは")
- `TalkyoTests/TestAudio/arigatou.wav` ("ありがとうございます")
- `TalkyoTests/TestAudio/sayounara.wav` ("さようなら")  
- `TalkyoTests/TestAudio/weather.wav` ("今日は良い天気ですね")
- `TalkyoTests/TestAudio/library.wav` ("図書館で本を読んでいます")
- `TalkyoTests/TestAudio/test_metadata.json` (metadata for tests)

### 4. Project Configuration

Ensure these settings in your test targets:

**TalkyoTests (Unit Tests):**
- Target Membership: Add all Swift test files
- Bundle Resources: Add `TestAudio/` folder
- Framework Dependencies: `@testable import Talkyo`

**TalkyoUITests (UI Tests):**
- Target Membership: Add UI test files
- Test Host: Talkyo app
- Framework Dependencies: `XCTest`

## Test Architecture

### Dependency Injection
- `AudioRecorderProtocol` enables swapping real/mock implementations
- `TranscriptionService` accepts injected dependencies via initializer
- `MockAudioRecorder` simulates recording with pre-loaded audio data

### Test Scenarios Covered

**E2E Workflow Tests:**
- Complete transcription: record → transcribe → verify → play
- Live mode real-time transcription  
- Swipe-to-cancel functionality
- Different recognition modes (On-Device/Server/Hybrid)
- Error handling for empty recordings
- UI state validation during recording

**Integration Tests:**
- Standard vs Live transcription workflows
- Furigana generation with kanji text
- Transcription timing measurement
- Recognition mode switching
- Recording lifecycle management

**Component Tests:**
- MockAudioRecorder functionality
- Audio buffer callback simulation
- Test audio loading and playback

## Running Tests

### Unit & Integration Tests
```bash
# Run in Xcode
CMD+U to run all tests

# Command line
xcodebuild test -scheme Talkyo -destination 'platform=iOS Simulator,name=iPhone 15'
```

### UI Tests (E2E)
```bash
# Run in Xcode with test mode
xcodebuild test -scheme Talkyo -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:TalkyoUITests

# Tests automatically launch app with --uitesting flag
# This enables test audio loading controls in the UI
```

### Test Data Verification

The tests verify:
- **Exact transcription matches** for controlled audio input
- **Furigana generation** for kanji characters  
- **UI state consistency** throughout recording workflow
- **Performance metrics** (transcription timing)
- **Error handling** for edge cases

### Expected Results

With the generated test audio, you should see:
- ✅ Basic greetings transcribed accurately
- ✅ Complex sentences with proper furigana
- ✅ All UI interactions working correctly
- ✅ Live mode providing real-time updates
- ✅ Recognition modes functioning properly

## File Structure

```
TalkyoTests/
├── README.md                              # This file
├── TestAudio/
│   ├── konnichiwa.wav                    # Generated test audio
│   ├── arigatou.wav
│   ├── sayounara.wav  
│   ├── weather.wav
│   ├── library.wav
│   └── test_metadata.json               # Audio metadata
├── MockAudioRecorder.swift               # Mock implementation
├── MockAudioRecorderTests.swift          # Mock component tests  
├── TranscriptionServiceIntegrationTests.swift  # Integration tests
├── TestAudioManager.swift                # Test data management
└── TalkyoE2ETests.swift                  # End-to-end UI tests
```

## Implementation Notes

- **Physical Device Recommended**: While simulator supports microphone, testing on device provides more realistic results
- **Test Audio Quality**: Generated with ElevenLabs multilingual model for consistent Japanese pronunciation
- **Mock Strategy**: Tests use dependency injection rather than global mocks for better isolation
- **Accessibility**: All UI components have identifiers for reliable test automation

This implementation fully addresses the requirements in Issue #3 and provides a robust testing foundation for the Talkyo app.