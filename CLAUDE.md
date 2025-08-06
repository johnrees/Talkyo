# Talkyo - iOS Japanese Voice Transcription App

## Overview
Talkyo is a modern iOS app for Japanese speech transcription using Apple's Speech Recognition framework. It features push-to-talk recording with swipe-to-cancel, both standard and real-time transcription modes, automatic punctuation, and furigana display.

## Architecture

### ContentView.swift
- Push-to-talk interface with swipe-to-cancel gesture
- Transcription mode selector (Standard/Live)
- Speech recognition mode selector (On-Device/Server/Hybrid)
- Displays transcription results with furigana above kanji
- Playback controls for recorded audio

### TranscriptionService.swift
- Coordinates transcription workflow for both standard and live modes
- Manages application state and UI updates
- Handles real-time transcription callbacks
- Clean separation between live and standard transcription flows

### SpeechRecognizer.swift
- Wrapper for Apple's Speech Recognition framework
- Supports both file-based and real-time streaming transcription
- Three recognition modes: On-Device, Server, Hybrid
- Handles partial and final transcription results
- Japanese (ja-JP) with automatic punctuation

### AudioRecorder.swift
- Audio recording and playback (16kHz mono WAV)
- Provides audio buffers for live transcription
- Haptic feedback: Light (start), Medium (stop), Heavy (cancel)
- Supports mid-capture cancellation

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

1. **Transcription Modes**:
   - Standard: Process after recording (more accurate)
   - Live: Real-time transcription while speaking
2. **Push-to-Talk**: Hold to record, swipe away to cancel
3. **Recognition Modes**: On-device, server, or hybrid
4. **Furigana Display**: Hiragana readings above kanji
5. **Haptic Feedback**: Tactile feedback for all actions
6. **Audio Playback**: Review recordings after transcription

## Technical Details

### Audio Configuration
- 16kHz mono WAV format
- Real-time audio buffer streaming for live mode
- Haptic feedback system for user actions

### Speech Recognition
- Japanese (ja-JP) with automatic punctuation
- File-based recognition for standard mode
- Audio buffer streaming for live mode
- Configurable on-device/server/hybrid processing

## Code Architecture Principles

- **Modern Swift**: Uses async/await, Combine, and latest Swift conventions
- **Clear Separation**: Each class has a single, well-defined responsibility
- **Error Handling**: Proper error types and async error propagation
- **Access Control**: Appropriate use of private/public modifiers
- **Documentation**: Self-documenting code with clear naming
- **Testing**: Designed for testability with dependency injection

## Swift 6.1+ Style Guidelines

### Naming & Conventions
- Use `UpperCamelCase` for types, `lowerCamelCase` for properties/functions
- Choose descriptive names (e.g., `calculateMonthlyRevenue()` not `calcRev`)
- Prefer `struct` for models and data, use `class` only when reference semantics required
- Leverage Swift's powerful enums with associated values for state representation
- Prefer early return pattern over nested conditionals

### Optionals & Error Handling
- Use optionals with `if let`/`guard let` for nil handling
- Never force-unwrap (`!`) without absolute certainty - prefer `guard` with failure path
- Use `do/try/catch` for error handling with meaningful error types
- Handle or propagate all errors - no empty catch blocks

### Modern SwiftUI Data Flow (No ViewModels)
- Views as pure state expressions - no ViewModels required
- Use `@State` for view-specific state with enum-based view states
- Use `@Observable` macro for making model classes observable
- Use `@Environment` for app-wide services (Router, Theme, Account, etc.)
- Use `let` properties for feature-specific services
- Use `.task(id:)` and `.onChange(of:)` for side effects
- Pass state between views using `@Binding`

### Concurrency Best Practices
- **@MainActor**: All UI updates must use @MainActor isolation
- **Actors**: Use for expensive operations (disk I/O, network calls, computation)
- **async/await**: Always prefer over completion handlers
- **.task modifier**: Always use for async operations tied to view lifecycle (auto-cancellation)
- **Avoid Task { } in onAppear**: This doesn't cancel automatically and can cause memory leaks
- **Sendable**: All types crossing concurrency boundaries must be Sendable in Swift 6

### Code Organization
- Keep functions focused on single responsibility
- Break large functions (>50 lines) into smaller units
- Use extensions to organize by feature/protocol conformance
- Prefer `let` over `var` - immutability by default
- Use `[weak self]` in closures to prevent retain cycles
- Always include `self.` when referring to instance properties in closures

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
- Swipe-to-cancel gesture for discarding recordings
- Replaced audio beeps with haptic feedback
- 0.2s delay after button release to prevent cutting off speech

### Live Transcription (Completed)
- Real-time transcription mode with streaming audio buffers
- Toggle between Standard and Live transcription modes
- Partial transcription updates during recording
- Maintains all features (furigana, recognition modes) in both modes

## Future Development

See [TODO.md](TODO.md) for the complete development roadmap. The next priorities include saving transcriptions, adding English translation, and implementing pitch accent detection.

## Testing Guidelines

### Swift Testing Framework
- Use Swift Testing (`@Test`, `#expect`, `#require`) for all new tests
- Write descriptive test names explaining what they verify
- Test both happy paths and edge cases
- Add tests for bug fixes to prevent regression
- Use parameterized tests for data-driven scenarios

Example:
```swift
import Testing

@Test func userCanTranscribeJapanese() async throws {
    let recognizer = SpeechRecognizer()
    let result = try await recognizer.transcribe(audio: testAudio)
    #expect(result.text.contains("こんにちは"))
}
```

## XcodeBuildMCP Tool Usage

When building and testing, use XcodeBuildMCP tools instead of raw CLI commands:

```javascript
// Build for simulator
build_sim_name_proj({
    projectPath: "/path/to/Talkyo.xcodeproj",
    scheme: "Talkyo",
    simulatorName: "iPhone 16"
})

// Run tests
test_sim_name_proj({
    projectPath: "/path/to/Talkyo.xcodeproj",
    scheme: "Talkyo",
    simulatorName: "iPhone 16"
})

// UI automation
describe_ui({ simulatorUuid: "UUID" })
tap({ simulatorUuid: "UUID", x: 100, y: 200 })
```

## Data Persistence

When persistence is needed:
- Use SwiftData for complex relational data (never CoreData)
- Use UserDefaults for simple preferences
- Consider JSON files for small configuration data
- Only persist what truly needs to survive app restarts

## Performance Best Practices

- Use `.id()` modifier sparingly (forces view recreation)
- Implement Equatable on models for SwiftUI diffing optimization
- Use LazyVStack/LazyHStack for large lists
- Profile with Instruments when needed
- @Observable tracks only accessed properties (better than @Published)

## Accessibility Requirements

- Always provide `accessibilityLabel` for interactive elements
- Use `accessibilityIdentifier` for UI testing
- Implement `accessibilityHint` where actions aren't obvious
- Test with VoiceOver enabled
- Support Dynamic Type

## Security & Privacy

- Never log sensitive information (audio data, transcriptions with PII)
- Use Keychain for any credential storage
- All network calls must use HTTPS
- Request minimal permissions
- Follow App Store privacy guidelines