# Talkyo - Japanese Voice Transcription App

A simple iOS app that transcribes Japanese speech using WhisperKit and Whisper models.

## Features

- Push-to-talk interface (hold button to record)
- Real-time Japanese speech transcription
- Clean, minimal UI
- On-device processing (no internet required)

## Setup Instructions

### Method 1: Using WhisperKit (Recommended)

1. Open the project in Xcode
2. Go to File → Add Package Dependencies
3. Enter this URL: `https://github.com/argmaxinc/WhisperKit`
4. Click "Add Package" and add it to the Talkyo target
5. Open `WhisperModelHandler.swift` and uncomment the WhisperKit code sections
6. Build and run!

WhisperKit will automatically download an appropriate Whisper model on first launch.

### Method 2: Manual Core ML Model (Advanced)

If you specifically want to use Kotoba Whisper v2.2:

1. Install Python dependencies:
   ```bash
   pip install torch transformers coremltools
   ```

2. Run the provided conversion script:
   ```bash
   python convert_model.py
   ```

3. Add the generated `.mlpackage` files to your Xcode project

Note: Whisper models are complex and full conversion requires significant additional work.

## Usage

1. Launch the app
2. Grant microphone permissions when prompted
3. Hold down the blue microphone button to record
4. Release to stop recording and see the transcription
5. The transcribed Japanese text will appear in the gray box above

## Model Options

With WhisperKit, you can choose different model sizes:
- `tiny`: Fastest, least accurate
- `base`: Good balance (default)
- `small`: Better accuracy
- `medium`: Best accuracy for Japanese

Change the model in `WhisperModelHandler.swift`:
```swift
whisperKit = try await WhisperKit(model: "small")
```

## Requirements

- iOS 18.0+
- iPhone or iPad
- Microphone access
- ~200MB free space for model

## Technical Details

- Uses AVAudioEngine for audio capture
- Converts audio to 16kHz mono for model compatibility
- Implements push-to-talk UI pattern
- WhisperKit for on-device inference
- Supports Japanese transcription out of the box