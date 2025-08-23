# macOS Implementation Plan for Talkyo

## Executive Summary

The **simplest and most idiomatic** approach for macOS is to use:
1. **System Notifications** (UNUserNotificationCenter) to display transcription results
2. **MenuBarExtra** for a minimal menu bar presence
3. **Global hotkey** for push-to-talk recording
4. **Shared core logic** with iOS

This approach follows Apple's HIG, requires minimal custom UI, and provides a native macOS experience.

## Why System Notifications?

According to Apple's Human Interface Guidelines:
- **Notifications** give people timely, high-value information they can understand at a glance
- They're non-intrusive and users can review them at their convenience
- They integrate with macOS notification center for history/management
- They're the simplest to implement - no custom windows or layouts needed
- Users already understand how to interact with them

## Architecture Overview

```
Talkyo (macOS) Architecture:
┌─────────────────────────────────────────┐
│         Menu Bar (MenuBarExtra)         │
│  ┌────────────────────────────────┐     │
│  │ 🎙️ Talkyo                      │     │
│  ├────────────────────────────────┤     │
│  │ ○ Recording Status             │     │
│  │ ─────────────────              │     │
│  │ Preferences...     ⌘,          │     │
│  │ Quit               ⌘Q          │     │
│  └────────────────────────────────┘     │
└─────────────────────────────────────────┘
                    ↓
         [Global Hotkey: ⌘⇧R]
                    ↓
┌─────────────────────────────────────────┐
│        System Notification              │
│  ┌────────────────────────────────┐     │
│  │ Talkyo                         │     │
│  │ Transcription Complete         │     │
│  │                                │     │
│  │ こんにちは                      │     │
│  │ Hello (translation)            │     │
│  │                                │     │
│  │ [Copy] [Dismiss]               │     │
│  └────────────────────────────────┘     │
└─────────────────────────────────────────┘
```

## Implementation Plan

### Phase 1: Project Setup (30 min)
- Add macOS target to existing Xcode project
- Update Package.swift for macOS platform (.macOS(.v14))
- Add KeyboardShortcuts SPM dependency
- Configure entitlements (microphone, speech recognition)

### Phase 2: Shared Code Refactoring (1 hour)
Extract platform-agnostic components:
- `SpeechRecognizer.swift` - Already mostly platform-agnostic
- `TranscriptionService.swift` - Remove UIKit dependencies
- `FuriganaGenerator.swift` - Already pure Swift
- `FuriganaToken.swift` - Already pure Swift

Platform abstractions needed:
```swift
// Remove UIKit haptics, not needed for macOS
#if os(iOS)
import UIKit
// Haptic feedback code
#endif
```

### Phase 3: Menu Bar App (1 hour)
```swift
@main
struct TalkyoMacApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        MenuBarExtra("Talkyo", systemImage: "mic.circle.fill") {
            MenuBarContentView(appState: appState)
        }
        .menuBarExtraStyle(.menu)
        
        Settings {
            PreferencesView(appState: appState)
        }
    }
}
```

Menu items:
- Recording indicator (● Recording... / ○ Ready)
- Divider
- Preferences... (⌘,)
- Quit (⌘Q)

### Phase 4: Hotkey Implementation (1 hour)
Using KeyboardShortcuts library:
```swift
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let startRecording = Self("startRecording")
}

class HotkeyManager: ObservableObject {
    init() {
        KeyboardShortcuts.onKeyDown(for: .startRecording) { [weak self] in
            self?.startRecording()
        }
        KeyboardShortcuts.onKeyUp(for: .startRecording) { [weak self] in
            self?.stopRecording()
        }
    }
}
```

Default: **⌘⇧R** (Command+Shift+R) for push-to-talk

### Phase 5: Notification Display (1 hour)
```swift
import UserNotifications

class NotificationManager {
    func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        try? await center.requestAuthorization(options: [.alert, .sound])
    }
    
    func showTranscriptionResult(text: String, translation: String?) {
        let content = UNMutableNotificationContent()
        content.title = "Transcription Complete"
        content.body = text
        if let translation = translation {
            content.subtitle = translation
        }
        content.sound = .default
        content.categoryIdentifier = "TRANSCRIPTION"
        
        // Add actions for copy/dismiss
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Show immediately
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}
```

### Phase 6: Preferences Window (30 min)
Simple SwiftUI preferences:
- Hotkey customization
- Recognition mode (on-device/server/hybrid)
- Translation settings
- Notification preferences

## Key Differences from iOS

| Feature | iOS | macOS |
|---------|-----|-------|
| **UI Paradigm** | Full-screen app | Menu bar + notifications |
| **Recording Trigger** | Touch & hold button | Global hotkey |
| **Results Display** | In-app view | System notification |
| **Haptic Feedback** | Yes (UIKit) | Not needed |
| **Audio Session** | AVAudioSession categories | Direct AVAudioEngine |
| **Settings** | In-app sheet | Preferences window |

## Shared Components (70% reuse)

**Fully Shared:**
- Speech recognition logic
- Audio recording engine
- Furigana generation
- Translation framework integration
- Data models and enums

**Platform-Specific:**
- UI/UX layer
- Hotkey vs touch handling
- Notification vs in-app display
- Settings presentation

## Benefits of This Approach

1. **Simplicity**: Uses native macOS patterns, no custom UI needed
2. **Familiarity**: Users know how notifications work
3. **Non-intrusive**: Doesn't interrupt workflow
4. **History**: Notifications remain in Notification Center
5. **Accessibility**: Works with VoiceOver and other assistive technologies
6. **Quick Implementation**: ~4-5 hours total development time

## Alternative Approaches Considered

**NSPopover** ❌
- More complex to implement
- Z-order issues with other windows
- Requires custom UI for transcription display

**Custom Toast Window** ❌  
- Non-standard for macOS
- Requires significant custom development
- May conflict with other apps

**Floating Panel** ❌
- Too intrusive for a utility app
- Not aligned with macOS design patterns

**System Notifications** ✅
- Native, familiar, simple
- Follows Apple HIG
- Minimal code required

## Testing Considerations

1. Test speech recognition availability on macOS
2. Verify microphone permissions flow
3. Test notification permissions and display
4. Verify hotkey doesn't conflict with system/other apps
5. Test with multiple languages/recognition modes

## Future Enhancements

- **Quick Actions**: Add notification actions for quick copy/translate
- **Notification Grouping**: Group multiple transcriptions
- **Rich Notifications**: Show furigana in notifications (if possible)
- **Shortcuts Integration**: Add Shortcuts app support
- **iCloud Sync**: Share settings between iOS/macOS

## Technical Implementation Notes

### Speech Recognition on macOS
- SFSpeechRecognizer is fully supported on macOS 10.15+
- Over 50 languages supported for server-based recognition
- Over 10 languages supported for on-device recognition
- Same API as iOS, minimal changes needed

### Audio Recording
- AVAudioEngine works identically on macOS
- No AVAudioSession needed (iOS-specific)
- Direct microphone access through AVAudioEngine input node

### Translation Framework
- Available on macOS 12.0+
- Same API as iOS
- Automatic language detection works the same

### Permissions
Required Info.plist keys for macOS:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>Talkyo needs microphone access to record and transcribe speech.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>Talkyo uses speech recognition to transcribe Japanese audio.</string>
```

### Build Configuration
Update Package.swift:
```swift
let package = Package(
    name: "Talkyo",
    platforms: [
        .iOS(.v18),
        .macOS(.v14)  // Add macOS support
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "TalkyoShared",
            dependencies: []
        ),
        .target(
            name: "TalkyoiOS",
            dependencies: ["TalkyoShared"]
        ),
        .target(
            name: "TalkyoMac",
            dependencies: [
                "TalkyoShared",
                "KeyboardShortcuts"
            ]
        )
    ]
)
```

## Code Organization

```
Talkyo/
├── Shared/                    # Cross-platform code (70% of codebase)
│   ├── Services/
│   │   ├── SpeechRecognizer.swift
│   │   ├── AudioRecorder.swift
│   │   └── TranscriptionService.swift
│   ├── Models/
│   │   ├── FuriganaGenerator.swift
│   │   ├── FuriganaToken.swift
│   │   └── TranscriptionModels.swift
│   └── Extensions/
│       └── PlatformHelpers.swift
├── iOS/                       # iOS-specific UI
│   ├── Views/
│   ├── TalkyoApp.swift
│   └── Info.plist
├── macOS/                     # macOS-specific UI
│   ├── Views/
│   │   ├── MenuBarContentView.swift
│   │   └── PreferencesView.swift
│   ├── Services/
│   │   ├── HotkeyManager.swift
│   │   └── NotificationManager.swift
│   ├── TalkyoMacApp.swift
│   └── Info.plist
└── Resources/
    └── Assets.xcassets       # Shared assets
```

## Conclusion

This approach provides the simplest, most macOS-native implementation while maximizing code reuse with iOS. By using system notifications instead of custom UI, we follow Apple's design guidelines and provide a familiar user experience. The implementation should take approximately 4-5 hours and result in a clean, maintainable codebase.

The key insight is that macOS users expect different interaction patterns than iOS users. While iOS users interact directly with the app, macOS users prefer unobtrusive utilities that stay out of the way. System notifications perfectly match this expectation while requiring minimal custom code.