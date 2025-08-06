# Copilot Custom Instructions for Talkyo

## Expert Swift Rules
This project includes comprehensive Swift development rules in `.cursor/rules/` directory. While these are primarily for Cursor IDE, they contain expert Swift patterns that should be followed by all AI assistants:
- `swift-ios-project.mdc` - Project structure and architecture
- `swiftui-patterns.mdc` - Modern SwiftUI state management
- `swift-concurrency.mdc` - Swift 6 concurrency patterns
- `swift-testing.mdc` - Testing best practices
- `xcodebuildmcp-tools.mdc` - Build tool usage
- `foundation-models.mdc` - Foundation type patterns
- `general-rules.mdc` - Swift coding standards

## Project Overview
- This is a native iOS app for Japanese speech transcription built with Swift 6.1+ and SwiftUI
- Targets iOS 18.0+ for latest Speech Recognition and SwiftUI features
- All concurrency uses Swift Concurrency (async/await, actors, @MainActor)

## Architecture Guidelines
- Use Model-View (MV) pattern with native SwiftUI state management
- DO NOT use ViewModels or MVVM - leverage SwiftUI's built-in state mechanisms
- Use `@State`, `@Observable`, `@Environment`, and `@Binding` for state management
- Views should be pure state expressions

## Code Style Requirements
- Use `UpperCamelCase` for types, `lowerCamelCase` for properties/functions
- Prefer `struct` over `class` unless reference semantics are required
- Never force-unwrap optionals without absolute certainty
- Use `guard` with early return pattern over nested conditionals
- Always handle or propagate errors - no empty catch blocks

## Concurrency Rules
- All UI updates must use `@MainActor` isolation
- Use actors for expensive operations (disk I/O, network, computation)
- Always use `.task` modifier for async operations (auto-cancellation)
- NEVER use `Task { }` in `onAppear` - causes memory leaks
- All types crossing concurrency boundaries must be Sendable

## Japanese Language Features
- Support furigana (ruby text) display above kanji
- Use Japanese tokenizer for accurate text processing
- Handle both standard and live transcription modes
- Support on-device, server, and hybrid recognition

## Testing Requirements
- Use Swift Testing framework (`@Test`, `#expect`, `#require`)
- Test on physical device (audio features don't work in simulator)
- Write tests for both happy paths and edge cases
- Add regression tests for bug fixes

## Build & Development
- Use XcodeBuildMCP tools for building and testing
- Prefer `build_sim_name_proj` over raw xcodebuild commands
- Test with `test_sim_name_proj` for simulator testing
- Use `describe_ui` and UI automation tools for UI testing

## Data & Persistence
- Use SwiftData for complex relational data (never CoreData)
- Use UserDefaults for simple preferences
- Consider JSON files for configuration
- Only persist what truly needs to survive app restarts

## Security & Privacy
- Never log sensitive audio data or transcriptions with PII
- Request minimal permissions (microphone, speech recognition)
- Use Keychain for any credential storage
- All network calls must use HTTPS

## Accessibility
- Always provide `accessibilityLabel` for interactive elements
- Use `accessibilityIdentifier` for UI testing
- Test with VoiceOver enabled
- Support Dynamic Type

## Key Files
- `ContentView.swift` - Main UI with push-to-talk interface
- `TranscriptionService.swift` - Coordinates transcription workflow
- `SpeechRecognizer.swift` - Wraps Apple's Speech Recognition
- `AudioRecorder.swift` - Audio recording and playback
- `FuriganaTextView.swift` - Displays Japanese with furigana
- `CLAUDE.md` - Comprehensive project documentation

## Important Notes
- Microphone and speech recognition permissions are required
- Minimum iOS 18.0 for latest features
- Uses KosugiMaru-Regular font for Japanese text
- Haptic feedback for all user actions
- 16kHz mono WAV format for audio