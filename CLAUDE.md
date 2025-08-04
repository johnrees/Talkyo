# Talkyo - iOS Japanese Voice Transcription App

## Overview
Talkyo is a modern iOS app for Japanese speech transcription using Apple's Speech Recognition framework. It features push-to-talk recording, real-time transcription with automatic punctuation, and automatic furigana generation.

## Architecture

### ContentView.swift
- Push-to-talk interface with swipe-to-cancel gesture
- Speech recognition mode selector (On-Device, Server, Hybrid)
- Displays transcription results with furigana above kanji
- Playback controls for recorded audio
- 0.2s delay after button release to catch end of speech

### TranscriptionService.swift
- Central coordinator for the transcription workflow
- Manages application state and UI updates
- Handles async transcription processing
- Provides clean public API with proper error handling
- Uses Combine for reactive state management

### SpeechRecognizer.swift
- Modern wrapper around Apple's Speech Recognition framework
- Supports three recognition modes:
  - On-Device: Fast, private, works offline
  - Server: More accurate, requires internet
  - Hybrid: System chooses best option
- Configured for Japanese (ja-JP) with automatic punctuation
- Async/await based API with proper error types
- Implements SFSpeechRecognizerDelegate for availability monitoring

### AudioRecorder.swift
- Audio recording and playback in 16kHz mono WAV format
- Haptic feedback for recording start/stop/cancel
- Supports cancelling recordings mid-capture
- Saves recordings to app's documents directory

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

1. **Push-to-Talk**: Hold to record, release to transcribe, swipe away to cancel
2. **Recognition Modes**: On-device (fast/private), server (accurate), or hybrid
3. **Automatic Punctuation**: Adds punctuation based on speech patterns
4. **Furigana Display**: Hiragana readings above kanji characters
5. **Audio Playback**: Review recordings after transcription
6. **Haptic Feedback**: Tactile feedback for recording actions
7. **Performance Metrics**: Shows transcription time and mode used

## Technical Details

### Audio Configuration
- Sample rate: 16kHz mono WAV format
- Haptic feedback: Light (start), Medium (stop), Heavy (cancel)
- Files saved to app's documents directory

### Speech Recognition
- Locale: ja-JP (Japanese)
- Automatic punctuation enabled
- Supports on-device and server-based recognition

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
- Added 0.2s delay after button release to prevent cutting off speech
- Swipe-to-cancel gesture for discarding recordings
- Replaced audio beeps with haptic feedback for all recording actions

## Future Development

See [TODO.md](TODO.md) for the complete development roadmap. The next priorities include saving transcriptions, adding English translation, and implementing pitch accent detection.