# Talkyo - iOS Japanese Voice Transcription App

## Overview
Talkyo is a simple iOS app for Japanese speech transcription using WhisperKit. It features push-to-talk recording, real-time transcription, and automatic furigana generation.

## Architecture

### ContentView.swift
- Main UI with push-to-talk button
- Displays transcription results
- Shows playback button when recording exists

### TranscriptionService.swift
- Coordinates between audio recording and transcription
- Manages app state and UI updates
- Handles timing and error cases

### WhisperModelHandler.swift
- Wraps WhisperKit for Japanese transcription
- Loads and manages the Whisper model
- Configures optimal settings for Japanese

### AudioRecorder.swift
- Handles audio recording and playback
- Converts audio to 16kHz for Whisper
- Saves recordings as WAV files
- Plays system beeps before/after recording
- 0.5s delay after start beep to prevent audio bleed

### FuriganaGenerator.swift
- Generates hiragana readings for kanji
- Uses iOS Japanese tokenizer
- Filters out unnecessary furigana

## Key Features

1. **Push-to-Talk**: Hold button to record, release to transcribe
2. **Japanese Optimization**: Forced Japanese language detection
3. **Furigana Support**: Automatic readings for kanji/katakana
4. **Playback**: Review recordings after transcription
5. **Audio Feedback**: Beep sounds indicate recording start/stop

## Technical Notes

### Audio Recording
- Uses system sounds 1113 (start) and 1114 (stop) for beeps
- 0.5 second delay after start beep prevents audio bleeding into recording
- Recording at 16kHz mono for Whisper compatibility
- Audio saved as WAV files in documents directory

## Development Guidelines

- Keep code simple and focused
- Separate concerns into distinct classes
- Use SwiftUI and Combine for reactive UI
- Test on physical device (audio doesn't work in simulator)

## Future Enhancements

- Multiple model size options
- Transcription history
- Export functionality
- Dictionary integration