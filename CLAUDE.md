# Talkyo - iOS Japanese Voice Transcription App

## Overview
Talkyo is a modern iOS app for Japanese speech transcription using Apple's Speech Recognition framework. It features push-to-talk recording with swipe-to-cancel, both standard and real-time transcription modes, automatic punctuation, and furigana display.

## Architecture

### ContentView.swift
- Push-to-talk interface with swipe-to-cancel gesture
- Transcription mode selector (Standard/Live)
- Speech recognition mode selector (On-Device/Server/Hybrid)
- Displays transcription results with furigana above kanji
- Playback controls for recorded audio

### TranscriptionService.swift
- Coordinates transcription workflow for both standard and live modes
- Manages application state and UI updates
- Handles real-time transcription callbacks
- Clean separation between live and standard transcription flows

### SpeechRecognizer.swift
- Wrapper for Apple's Speech Recognition framework
- Supports both file-based and real-time streaming transcription
- Three recognition modes: On-Device, Server, Hybrid
- Handles partial and final transcription results
- Japanese (ja-JP) with automatic punctuation

### AudioRecorder.swift
- Audio recording and playback (16kHz mono WAV)
- Provides audio buffers for live transcription
- Haptic feedback: Light (start), Medium (stop), Heavy (cancel)
- Supports mid-capture cancellation

### FuriganaGenerator.swift
- Generates hiragana readings for Japanese text
- Uses iOS Japanese tokenizer for accurate readings
- Returns array of FuriganaToken objects pairing text with readings
- Filters out unnecessary furigana (when identical to input)
- Implemented as a stateless enum with static methods

### FuriganaToken.swift
- Data structure representing a text segment with optional furigana reading
- Contains logic to determine if furigana display is needed
- Checks for kanji and katakana characters

### FuriganaTextView.swift
- Displays Japanese text with furigana (ruby text) above kanji
- Uses KosugiMaru-Regular font with bold/semibold weights
- 50% font size for furigana readings

## Key Features

1. **Transcription Modes**:
   - Standard: Process after recording (more accurate)
   - Live: Real-time transcription while speaking
2. **Push-to-Talk**: Hold to record, swipe away to cancel
3. **Recognition Modes**: On-device, server, or hybrid
4. **Furigana Display**: Hiragana readings above kanji
5. **Haptic Feedback**: Tactile feedback for all actions
6. **Audio Playback**: Review recordings after transcription

## Technical Details

### Audio Configuration
- 16kHz mono WAV format
- Real-time audio buffer streaming for live mode
- Haptic feedback system for user actions

### Speech Recognition
- Japanese (ja-JP) with automatic punctuation
- File-based recognition for standard mode
- Audio buffer streaming for live mode
- Configurable on-device/server/hybrid processing

## Code Architecture Principles

- **Modern Swift**: Uses async/await, Combine, and latest Swift conventions
- **Clear Separation**: Each class has a single, well-defined responsibility
- **Error Handling**: Proper error types and async error propagation
- **Access Control**: Appropriate use of private/public modifiers
- **Documentation**: Self-documenting code with clear naming
- **Testing**: Designed for testability with dependency injection

## Development Notes

- Test on physical device (audio features don't work in simulator)
- Microphone and speech recognition permissions required
- Minimum iOS 18.0 for latest features
- Uses SwiftUI and Combine for reactive UI updates

## Recent Updates

### Furigana Implementation (Completed)
- Successfully implemented proper ruby text (furigana) display
- Hiragana readings now appear directly above kanji characters
- Uses SwiftUI approach for reliable and maintainable implementation
- Proper alignment ensures clean visual presentation

### Font Integration (Completed)
- Integrated KosugiMaru-Regular font for Japanese text display
- Font registered in project settings via INFOPLIST_KEY_UIAppFonts
- Applied bold weight to main text and semibold to furigana for improved readability

### Recording Improvements (Completed)
- Swipe-to-cancel gesture for discarding recordings
- Replaced audio beeps with haptic feedback
- 0.2s delay after button release to prevent cutting off speech

### Live Transcription (Completed)
- Real-time transcription mode with streaming audio buffers
- Toggle between Standard and Live transcription modes
- Partial transcription updates during recording
- Maintains all features (furigana, recognition modes) in both modes

## Future Development

See [TODO.md](TODO.md) for the complete development roadmap. The next priorities include saving transcriptions, adding English translation, and implementing pitch accent detection.