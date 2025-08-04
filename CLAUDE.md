# Talkyo - iOS Japanese Voice Transcription App

## Overview
Talkyo is a simple iOS app for Japanese speech transcription using Apple's Core ML Speech Recognition. It features push-to-talk recording, real-time transcription, and automatic furigana generation.

## Architecture

### ContentView.swift
- Main UI with push-to-talk button
- Core ML configuration selector (On-Device, Server, Hybrid)
- Displays transcription results with kanji and kana on separate lines
- Shows playback button when recording exists

### TranscriptionService.swift
- Coordinates between audio recording and transcription
- Manages app state and UI updates
- Handles timing and error cases

### CoreMLModelHandler.swift
- Wraps Apple's Speech Recognition framework
- Supports three modes:
  - On-Device: Fast, private, works offline
  - Server: More accurate, requires internet
  - Hybrid: System chooses best option
- Configured for Japanese (ja-JP) recognition

### AudioRecorder.swift
- Handles audio recording and playback
- Saves recordings as WAV files at 16kHz
- Plays system beeps before/after recording
- 0.5s delay after start beep to prevent audio bleed

### FuriganaGenerator.swift
- Generates hiragana readings for kanji
- Uses iOS Japanese tokenizer
- Filters out unnecessary furigana

## Key Features

1. **Push-to-Talk**: Hold button to record, release to transcribe
2. **Core ML Options**: Choose between on-device, server, or hybrid recognition
3. **Dual Display**: Shows original text (kanji) and full kana reading below
4. **Playback**: Review recordings after transcription
5. **Audio Feedback**: Beep sounds indicate recording start/stop
6. **Performance Metrics**: Shows transcription time and mode used

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

- Transcription history
- Export functionality
- Dictionary integration
- True furigana display (ruby text above kanji)