# Talkyo - iOS Japanese Voice Transcription App

## Overview
Talkyo is a modern iOS app for Japanese speech transcription using Apple's Speech Recognition framework. It features push-to-talk recording with swipe-to-cancel, both standard and real-time transcription modes, automatic punctuation, and furigana display.

## Development Guidelines
This project includes comprehensive Swift development rules in `.cursor/rules/` that Claude should follow:
- **swift-ios-project.mdc**: Project structure and architecture patterns
- **swiftui-patterns.mdc**: Modern SwiftUI data flow and state management
- **swift-concurrency.mdc**: Swift 6 concurrency with actors and Sendable
- **swift-testing.mdc**: Swift Testing framework guidelines
- **xcodebuildmcp-tools.mdc**: Build and deployment tool usage
- **foundation-models.mdc**: Foundation types and patterns
- **general-rules.mdc**: General Swift coding standards

When working on this project, reference these rules for consistent, high-quality Swift code.

## Project Structure Note
Unlike the template structure in `.cursor/rules/swift-ios-project.mdc`, Talkyo currently uses a simpler structure with all Swift files directly in the Talkyo/ directory rather than a separate SPM package. The architectural principles and patterns from the rules still apply, but the file organization is flatter.

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
- Modern UIKit haptic feedback using UIImpactFeedbackGenerator and UINotificationFeedbackGenerator
- Supports mid-capture cancellation
- Audio session management with pause/resume for background audio

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
- 16kHz mono WAV format optimized for speech recognition
- Real-time audio buffer streaming for live mode
- Modern haptic feedback using UIKit generators for better user experience

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

## Code Quality Updates (2025 Best Practices)

### Clean Architecture
- Removed polling patterns in favor of proper @Observable property observation
- Eliminated redundant code and duplicate method signatures
- Consolidated related types into appropriate files (SpeechRecognitionResult moved to SpeechRecognizer)
- Simplified configuration structures and removed unnecessary nesting

### Modern Swift Patterns
- Replaced deprecated AudioToolbox with UIKit haptic feedback generators
- Added proper accessibility labels and hints for all interactive UI elements
- Removed weak self where unnecessary in structured concurrency
- Cleaned up imports and removed unused dependencies

### Audio Session Management
- Implemented proper audio interruption handling
- Background audio pauses during recording and resumes after
- Uses `.notifyOthersOnDeactivation` for seamless audio handoff

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
    projectPath: "/Users/john/Code/old-stuff/xcode/Talkyo/Talkyo.xcodeproj",
    scheme: "Talkyo",
    simulatorName: "iPhone 16"
})

// Run tests  
test_sim_name_proj({
    projectPath: "/Users/john/Code/old-stuff/xcode/Talkyo/Talkyo.xcodeproj",
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

## Swift Patterns Reference

### SwiftUI View Patterns
```swift
// Use @Observable for view models (iOS 17+)
@Observable
class TranscriptionModel {
    var text: String = ""
    var isRecording = false
}

// Views as pure state expressions
struct TranscriptionView: View {
    @State private var model = TranscriptionModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        // View is just a representation of state
    }
}

// Use .task for async operations (auto-cancellation)
.task {
    try? await loadData()
}

// NEVER use Task { } in onAppear - causes memory leaks
```

### Concurrency Patterns
```swift
// Actor for thread-safe operations
actor AudioProcessor {
    private var buffer: [Float] = []
    
    func process(_ samples: [Float]) async {
        // Thread-safe processing
    }
}

// @MainActor for UI updates
@MainActor
func updateUI() {
    // All UI updates here
}

// Sendable conformance for Swift 6
struct TranscriptionResult: Sendable {
    let text: String
    let confidence: Float
}
```

### Error Handling Patterns
```swift
enum TranscriptionError: LocalizedError {
    case microphoneAccessDenied
    case recognitionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .microphoneAccessDenied:
            return "Microphone access is required"
        case .recognitionFailed(let reason):
            return "Recognition failed: \(reason)"
        }
    }
}

// Use Result for explicit error handling
func transcribe() async -> Result<String, TranscriptionError> {
    // Implementation
}
```

### Testing Patterns
```swift
import Testing

@Test("Japanese text is transcribed correctly")
func transcribesJapanese() async throws {
    let recognizer = SpeechRecognizer()
    let result = try await recognizer.transcribe(testAudio)
    #expect(result.contains("こんにちは"))
}

@Test("Furigana is generated for kanji", arguments: [
    ("新しい", "あたらしい"),
    ("日本", "にほん")
])
func generatesFurigana(input: String, expected: String) {
    let furigana = FuriganaGenerator.generate(for: input)
    #expect(furigana.reading == expected)
}
```

## Key Principles from Expert Rules

1. **No ViewModels**: Use SwiftUI's native state management
2. **Swift Concurrency Only**: No GCD, no completion handlers
3. **Value Types First**: Prefer struct over class
4. **Early Returns**: Guard and fail fast
5. **Sendable Everything**: All types crossing concurrency boundaries
6. **Test Everything**: Use Swift Testing, not XCTest
7. **Accessibility Always**: Every interactive element needs labels
8. **No Force Unwrapping**: Use guard or if let
9. **Use .task**: For view lifecycle async work
10. **XcodeBuildMCP Tools**: For all build and test operations

## Using the Development Rules

When working on this project:
1. **Read the relevant .cursor/rules files** before making changes to ensure consistency
2. **Follow the patterns** demonstrated in the Swift Patterns Reference section above
3. **Use XcodeBuildMCP tools** as shown in the examples rather than raw CLI commands
4. **Apply Swift 6 concurrency** patterns with proper Sendable conformance
5. **Write tests** using Swift Testing framework for all new features

The rules in `.cursor/rules/` represent expert Swift knowledge and should be treated as the authoritative guide for code quality and architecture decisions in this project.