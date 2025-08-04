# Talkyo - iOS Japanese Voice Transcription App

## Project Overview
Talkyo is an iOS application that transcribes Japanese speech in real-time using WhisperKit and Core ML. The app features a push-to-talk interface for recording audio and displays the transcribed Japanese text with furigana readings for kanji and katakana.

## Core Features

### 1. Push-to-Talk Recording
- Hold button to record Japanese speech
- Release button to stop recording and trigger transcription
- Visual feedback with color change (blue → red) when recording
- Clear previous transcription when starting new recording

### 2. Real-time Japanese Transcription
- Uses WhisperKit with Whisper "base" model for accurate Japanese recognition
- Forced Japanese language detection to prevent misrecognition
- Displays transcription time in milliseconds
- Optimized for iOS devices with on-device processing

### 3. Furigana Support
- Automatically generates hiragana readings for kanji characters
- Shows hiragana readings for katakana words (e.g., カナダ → かなだ)
- Hides furigana for text already in hiragana
- Displayed in smaller gray text below the main transcription

### 4. User Interface
- Clean, minimalist design with large microphone button
- Transcribed text displayed in large font (32pt)
- Furigana readings in smaller font (16pt) below
- Transcription time shown in blue (e.g., "412ms")
- Placeholder text "話してください" when no transcription

## Technical Implementation

### Platform
- iOS (Swift)
- Target iOS 18.0+
- SwiftUI for modern UI development

### Architecture
- SwiftUI for modern declarative UI
- Combine framework for reactive state management
- AVAudioEngine for audio recording
- WhisperKit for speech recognition
- CoreText and CFStringTransform for furigana generation

### Key Components
1. **ContentView.swift**: Main UI with push-to-talk button and text display
2. **TranscriptionManager.swift**: Handles audio recording and WhisperKit integration
3. **WhisperModelHandler.swift**: Manages WhisperKit model loading and transcription
4. **Audio Processing**: 
   - Records at device's native sample rate
   - Converts to 16kHz for Whisper model compatibility
   - Uses AVAudioConverter for format conversion

### Dependencies
- **WhisperKit**: Swift package for on-device Whisper speech recognition
  - GitHub: https://github.com/argmaxinc/WhisperKit
  - Model: "base" (approximately 150MB)
  - Supports Japanese transcription out of the box

## Development Guidelines

### Code Style
- Follow Swift API Design Guidelines
- Use descriptive variable and function names
- Implement proper error handling
- Write unit tests for core functionality

### UI/UX Principles
- Minimalist design focused on learning
- High contrast for readability
- Smooth animations that don't distract from learning
- Intuitive controls for playback and navigation

### Accessibility
- VoiceOver support for navigation
- Dynamic Type support for text sizing
- Color contrast meeting WCAG guidelines

## Current Project Structure
```
Talkyo/
├── Talkyo/
│   ├── TalkyoApp.swift          # App entry point
│   ├── ContentView.swift        # Main UI with push-to-talk button
│   ├── TranscriptionManager.swift # Audio recording and transcription logic
│   ├── WhisperModelHandler.swift  # WhisperKit integration
│   └── Assets.xcassets/         # App icons and colors
├── Talkyo.xcodeproj/            # Xcode project file
├── README.md                    # Setup instructions
└── CLAUDE.md                    # This file
```

## Known Issues & Solutions

### iOS Simulator
- Audio recording crashes in iOS Simulator due to AVAudioEngine limitations
- Solution: Test on physical iOS device with developer mode enabled

### WhisperKit Model Download
- First launch requires downloading the Whisper model (~150MB)
- Requires internet connection for initial download
- Model is cached locally after first download

### Transcription Accuracy
- "tiny" model is fast but has poor Japanese accuracy
- "small" model is better but still may have issues
- "base" model (current) provides good balance of speed and accuracy
- "medium" model would provide best accuracy but slower

## Performance Metrics
- Transcription time: 400-600ms for short phrases with "base" model
- Audio recording: 16kHz mono, converted from device native format
- Memory usage: ~200MB with model loaded

## Future Enhancements
- Support for multiple Whisper model sizes with user selection
- Save transcription history
- Export transcriptions
- Real-time transcription (streaming)
- Support for other languages beyond Japanese
- Improved furigana with proper word boundaries
- Integration with Japanese dictionaries for word lookup