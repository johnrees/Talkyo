# Talkyo - iOS Japanese Voice Transcription App

## Overview
Talkyo is a modern iOS app for Japanese speech transcription using Apple's Speech Recognition framework. It features push-to-talk recording, real-time transcription with automatic punctuation, and automatic furigana generation.

## Architecture

### ContentView.swift
- Main UI with push-to-talk interface
- Speech recognition mode selector (On-Device, Server, Hybrid)
- Displays transcription results with furigana (ruby text) above kanji
- Playback controls for recorded audio
- Clean separation of view components
- 0.2s delay after button release before stopping recording to catch end of speech

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
- Handles audio recording and playback functionality
- Records at 16kHz mono in WAV format
- System sound feedback (beeps) for recording start/stop
- 0.5s delay after start beep to prevent audio bleeding
- Clean separation of recording, processing, and file management
- Proper memory management and resource cleanup

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
- SwiftUI view for displaying Japanese text with furigana above kanji
- Uses HStack with VStack overlays for proper alignment
- Displays small hiragana (50% font size) above kanji characters
- Aligns non-kanji text properly with furigana baseline
- Uses KosugiMaru-Regular font for better Japanese text rendering
- Bold font weight for main text, semibold for furigana

## Key Features

1. **Push-to-Talk**: Hold button to record, release to transcribe
2. **Recognition Modes**: Choose between on-device, server, or hybrid recognition
3. **Automatic Punctuation**: Adds periods, commas, and question marks based on speech patterns
4. **Furigana Display**: Shows hiragana readings directly above kanji characters (ruby text)
5. **Audio Playback**: Review recordings after transcription
6. **Audio Feedback**: System beeps indicate recording start/stop
7. **Performance Metrics**: Displays transcription time and recognition mode used

## Technical Details

### Audio Configuration
- Sample rate: 16kHz mono
- Format: WAV (PCM Float32)
- System sounds: 1113 (start), 1114 (stop)
- 0.5 second delay after start beep to prevent audio bleed
- Files saved to app's documents directory

### Speech Recognition
- Locale: ja-JP (Japanese)
- Punctuation: Enabled for iOS 16+
- Task hint: Dictation mode for optimal punctuation
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
- Added 0.2s delay after button release before stopping recording
- Prevents cutting off speech when users release button while still speaking
- Maintains snappy and responsive UI feel

## Future Development

See [TODO.md](TODO.md) for the complete development roadmap. The next priorities include saving transcriptions, adding English translation, and implementing pitch accent detection.