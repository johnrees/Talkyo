# Talkyo

A simple iOS app for Japanese speech transcription with furigana generation.

## Features

- **Push-to-Talk Recording**: Hold to record, release to transcribe, swipe to cancel
- **Japanese Speech Recognition**: Apple's Speech Recognition framework  
- **Furigana Display**: Hiragana readings above kanji characters
- **Custom Japanese Font**: KosugiMaru font for optimal readability
- **Recognition Modes**: On-device, server, or hybrid
- **Haptic Feedback**: Tactile feedback for recording actions
- **Audio Playback**: Review recordings after transcription

## Requirements

- iOS 18.0+
- Xcode 16.0+
- Physical iOS device (audio features don't work in simulator)

## Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/talkyo.git
   cd talkyo
   ```

2. Open the project in Xcode:
   ```bash
   open Talkyo.xcodeproj
   ```

3. Select your development team in the project settings

4. Build and run on a physical device (not simulator)

## Permissions

The app will request the following permissions on first launch:
- **Microphone**: Required for audio recording
- **Speech Recognition**: Required for transcription

## Usage

1. Launch the app
2. Select your preferred recognition mode
3. Press and hold the microphone button to record
4. Release to transcribe or swipe away to cancel
5. View transcribed text with furigana above kanji
6. Tap play to review your recording

## Architecture

See [CLAUDE.md](CLAUDE.md) for detailed architecture documentation.

## Development

See [TODO.md](TODO.md) for the development roadmap.

## License

[Add your license here]