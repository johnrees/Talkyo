# Talkyo

A simple iOS app for Japanese speech transcription with furigana generation.

## Features

- **Push-to-Talk Recording**: Hold to record, release to transcribe (with 0.2s grace period)
- **Japanese Speech Recognition**: Uses Apple's Speech Recognition framework
- **Ruby Text (Furigana) Display**: Shows hiragana readings directly above kanji characters
- **Custom Japanese Font**: Uses KosugiMaru font for optimal readability
- **Recognition Modes**: Choose between on-device (fast/private), server (accurate), or hybrid
- **Automatic Punctuation**: Adds periods and commas based on speech patterns
- **Audio Playback**: Review your recordings after transcription

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
2. Select your preferred recognition mode (On-Device, Server, or Hybrid)
3. Press and hold the microphone button to record
4. Release to stop recording and start transcription
5. View the transcribed text with furigana (hiragana) displayed above kanji characters
6. Tap the play button to review your recording

## Architecture

See [CLAUDE.md](CLAUDE.md) for detailed architecture documentation.

## Development

See [TODO.md](TODO.md) for the development roadmap.

## License

[Add your license here]