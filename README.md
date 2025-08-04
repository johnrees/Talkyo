# Talkyo - Japanese Voice Transcription App

A simple iOS app that transcribes Japanese speech using WhisperKit.

## Features

- Push-to-talk recording
- Real-time Japanese speech transcription  
- Automatic furigana generation for kanji
- Recording playback
- Clean, minimal UI

## Requirements

- iOS 18.0+
- iPhone or iPad
- ~50MB for Whisper model

## Setup

1. Open in Xcode
2. Build and run on device (not simulator)
3. Grant microphone permissions
4. Model downloads automatically on first launch

## Usage

1. Hold the blue microphone button to record
2. Release to transcribe
3. View transcription with furigana
4. Tap green button to replay recording

## Architecture

```
Talkyo/
├── ContentView.swift          # Main UI
├── TranscriptionService.swift # Coordinates workflow
├── WhisperModelHandler.swift  # WhisperKit integration
├── AudioRecorder.swift        # Audio recording/playback
└── FuriganaGenerator.swift    # Japanese text processing
```

## Technical Details

- Uses WhisperKit for on-device transcription
- Records at 16kHz for Whisper compatibility
- Generates furigana using iOS Japanese tokenizer
- All processing done on-device