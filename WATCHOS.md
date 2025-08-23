# Apple Watch Ultra Integration for Talkyo

## Overview
This document outlines the implementation plan for adding Apple Watch Ultra Action Button support to Talkyo, enabling users to record and transcribe Japanese speech directly from their watch.

## Key Features

### Action Button Integration
- **Single Press**: Start recording
- **Second Press**: Stop recording and transcribe
- **Long Press**: Reserved for system (Emergency SOS)
- **Swipe Gesture**: Cancel recording (similar to iPhone app)

### Recording Modes
1. **Connected Mode** (iPhone nearby)
   - Real-time audio streaming to iPhone
   - Immediate transcription results
   - Lower latency, higher quality

2. **Standalone Mode** (iPhone distant/in bag)
   - Local audio recording on Watch
   - Background sync when reconnected
   - Offline capability

## Technical Architecture

### watchOS App Components

#### 1. Action Button Intent (`StartRecordingIntent.swift`)
```swift
import AppIntents

struct StartRecordingIntent: AppIntent, StartWorkoutIntent {
    static var title: LocalizedStringResource = "Start Recording"
    static var description = IntentDescription("Start recording audio for transcription")
    
    @Parameter(title: "Recording Mode")
    var workoutStyle: WorkoutStyle
    
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        // Trigger recording start
        await RecordingManager.shared.startRecording()
        return .result(value: true)
    }
}
```

#### 2. Audio Recording Manager (`WatchRecordingManager.swift`)
- Uses AVAudioRecorder for local recording
- Configuration: 16kHz mono (matching iPhone app)
- File format: .m4a (better watchOS compatibility than .caf)
- Buffer size optimized for streaming

#### 3. Communication Layer (`WatchConnectivityManager.swift`)
- WCSession for iPhone communication
- Real-time audio streaming when reachable
- File transfer for offline recordings
- Bidirectional result sync

#### 4. UI Components
- `RecordingView.swift`: Minimal recording interface
- `TranscriptionResultView.swift`: Display results with furigana
- Haptic feedback using WKInterfaceDevice

### iOS App Modifications

#### 1. Watch Connectivity (`iOSWatchConnectivityManager.swift`)
- Receive audio streams/files from Watch
- Process with existing SpeechRecognizer
- Send transcription results back

#### 2. Background Processing
- Handle audio reception in background
- Process transcription queue
- Update Watch with results

## Implementation Steps

### Phase 1: Basic Watch App (Week 1)
1. Create new watchOS target in Xcode project
2. Implement basic audio recording with AVAudioRecorder
3. Add minimal UI for recording status
4. Test audio quality and file formats

### Phase 2: Action Button Integration (Week 1)
1. Implement StartRecordingIntent conforming to StartWorkoutIntent
2. Register intent with system
3. Configure Info.plist for workout processing
4. Test Action Button assignment in Settings

### Phase 3: Communication Layer (Week 2)
1. Add WatchConnectivity to both apps
2. Implement audio streaming for connected mode
3. Add file transfer for standalone mode
4. Handle connection state changes

### Phase 4: Transcription Integration (Week 2)
1. Modify iOS TranscriptionService for Watch audio
2. Implement result callbacks to Watch
3. Add furigana display on Watch
4. Test end-to-end flow

### Phase 5: Polish & Optimization (Week 3)
1. Add proper error handling
2. Implement battery optimization
3. Add haptic feedback patterns
4. Test offline scenarios

## Audio Configuration

### Watch Recording Settings
```swift
let audioSettings = [
    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
    AVSampleRateKey: 16000,  // Match iPhone app
    AVNumberOfChannelsKey: 1,
    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
]
```

### Streaming Configuration
- Chunk size: 1024 samples
- Compression: AAC for bandwidth efficiency
- Latency target: <100ms when connected

## User Experience Flow

### First-Time Setup
1. User installs Talkyo on iPhone
2. Watch app automatically installs
3. User opens Watch Settings → Action Button
4. Selects Talkyo from app list
5. Grants microphone permissions

### Recording Flow
1. **Press Action Button** → Haptic pulse (recording starts)
2. **Speak Japanese** → Audio captured/streamed
3. **Press Again** → Haptic pulse (recording stops)
4. **View Results** → Transcription appears with furigana
5. **Digital Crown** → Scroll through long transcriptions

## Technical Considerations

### Limitations
- SFSpeechRecognizer not available on watchOS
- All transcription must occur on iPhone
- Audio quality sufficient for speech, not music
- Battery impact during extended recording

### Performance Optimizations
- Downsample audio for streaming (16kHz)
- Use background queues for processing
- Implement aggressive memory management
- Cache recent transcriptions locally

### Error Handling
- iPhone disconnection during recording
- Microphone permission denied
- Storage full scenarios
- Network timeout for syncing

## Permissions Required

### Watch App
- `NSMicrophoneUsageDescription`: "Talkyo needs microphone access to record speech for transcription"

### iPhone App (Update)
- Add to existing `NSMicrophoneUsageDescription` 
- `NSSpeechRecognitionUsageDescription` (already present)

## File Structure

```
Talkyo Watch App/
├── TalkyoWatchApp.swift                 # App entry point
├── Models/
│   ├── RecordingState.swift            # Recording state management
│   └── WatchTranscriptionResult.swift  # Result model
├── Services/
│   ├── WatchRecordingManager.swift     # Audio recording
│   ├── WatchConnectivityManager.swift  # iPhone communication
│   └── HapticManager.swift            # Haptic feedback
├── Intents/
│   └── StartRecordingIntent.swift     # Action Button intent
├── Views/
│   ├── ContentView.swift              # Main view
│   ├── RecordingView.swift            # Recording interface
│   └── TranscriptionResultView.swift  # Results display
└── Info.plist                          # Configuration
```

## Testing Strategy

### Unit Tests
- Audio recording functionality
- WatchConnectivity message handling
- Intent perform() methods

### Integration Tests
- End-to-end recording → transcription
- Offline/online mode transitions
- Background sync reliability

### Device Testing
- Apple Watch Ultra (primary target)
- Apple Watch Series 7+ (compatibility)
- Various iPhone models (iOS 18+)

## Future Enhancements

### Version 2.0
- Complication showing last transcription
- Live Activities on iPhone during recording
- Multiple language support
- Custom haptic patterns per action

### Version 3.0
- On-device speech recognition (when Apple adds support)
- Direct translation on Watch
- Voice feedback for transcriptions
- Shortcuts integration for automation

## Development Timeline

- **Week 1**: Basic Watch app with Action Button
- **Week 2**: Communication and transcription
- **Week 3**: Polish, testing, and optimization
- **Total estimate**: 3 weeks for MVP

## Success Metrics

- Action Button response time: <50ms
- Recording start latency: <100ms
- Transcription delivery (connected): <2s
- Battery impact: <10% per hour of use
- Crash rate: <0.1%

## References

- [Apple: Action Button Documentation](https://developer.apple.com/documentation/appintents/actionbutton)
- [Apple: WatchConnectivity Framework](https://developer.apple.com/documentation/watchconnectivity)
- [Apple: AVAudioRecorder for watchOS](https://developer.apple.com/documentation/avfaudio/avaudiorecorder)
- [GitHub: WatchActionButtonExample](https://github.com/KhaosT/WatchActionButtonExample)