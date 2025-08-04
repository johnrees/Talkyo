# Talkyo Development Roadmap

## Phase 0: Visual Improvements ✅ COMPLETED

### 0.1 Ruby Text (Furigana) Display ✅ COMPLETED (2025-08-04)
- [x] Replace current two-line display with proper ruby text (furigana above kanji)
- [x] Research iOS text rendering options:
  - NSAttributedString with kCTRubyAnnotationAttributeName (attempted, had memory issues)
  - Custom SwiftUI view with Text overlays (selected approach)
  - Web view with HTML ruby tags (implemented as fallback)
- [x] Create FuriganaTextView component that positions hiragana above kanji
- [x] Handle text wrapping and sizing appropriately
- [x] Ensure proper alignment between base text and ruby annotations
- [x] Test with various text lengths and kanji combinations

### Implementation Details:
- Created FuriganaToken data structure to pair text segments with readings
- Modified FuriganaGenerator to return token arrays
- Implemented SwiftUI-based FuriganaTextView for reliable rendering
- Furigana appears at 50% font size above kanji characters
- Non-kanji text is properly aligned with vertical padding

## Phase 1: Core Enhancements ⭐ CURRENT PRIORITY

### 1.1 Save Transcriptions & Recordings
- [ ] Create data model for saved sessions (timestamp, audio file, transcription, kanji/kana)
- [ ] Add SwiftUI list view for transcription history
- [ ] Implement Core Data or file-based storage
- [ ] Add export functionality (text, audio, or both)
- [ ] Add delete/edit capabilities for saved items

### 1.2 English Translation
- [ ] Integrate translation API (Apple Translate framework or third-party)
- [ ] Add toggle to show/hide English translation
- [ ] Cache translations to reduce API calls
- [ ] Display translation below kana reading

## Phase 2: Learning Features

### 2.1 Pitch Accent Detection
- [ ] Research iOS pitch detection frameworks (Core Audio, AVFoundation)
- [ ] Implement real-time pitch tracking during recording
- [ ] Create pitch accent notation system (H/L markers or visual graph)
- [ ] Store pitch data with transcriptions

### 2.2 Reference Comparison
- [ ] Build database of reference recordings with correct pitch patterns
- [ ] Implement pitch pattern comparison algorithm
- [ ] Create visual diff showing user vs reference pitch
- [ ] Add scoring/feedback system

## Phase 3: Interactive Features

### 3.1 Karaoke-Style Playback
- [ ] Implement word-level timestamp detection in transcription
- [ ] Create bouncing ball animation synchronized with audio
- [ ] Add adjustable playback speed
- [ ] Highlight current character/word during playback

### 3.2 Shadowing Practice
- [ ] Create library of reference recordings
- [ ] Build shadowing mode UI (play reference → record user → compare)
- [ ] Implement side-by-side waveform visualization
- [ ] Add practice tracking and progress metrics

## Phase 4: Advanced Features

### 4.1 Pitch Accent Validation
- [ ] Integrate pitch accent dictionary (OJAD or similar)
- [ ] Mark incorrect pitch patterns in real-time
- [ ] Provide correction suggestions
- [ ] Add pitch pattern practice exercises

### 4.2 Analytics & Progress
- [ ] Track user statistics (accuracy, pitch correctness, practice time)
- [ ] Create progress charts and learning insights
- [ ] Implement spaced repetition for problem areas
- [ ] Export progress reports

## Technical Considerations

### Ruby Text Implementation ✅ COMPLETED
- Attempted Core Text framework with CTRubyAnnotation but encountered memory management issues
- Successfully implemented SwiftUI approach with Text overlays
- Performance is good with the SwiftUI implementation
- Edge cases handled through proper token generation
- VoiceOver support through standard SwiftUI Text components

### Audio Processing
- Investigate Core Audio for pitch detection
- Consider using Accelerate framework for FFT analysis
- May need to increase sample rate for accurate pitch detection

### UI/UX
- Design intuitive pitch visualization (musical notation vs graph)
- Ensure karaoke animation is smooth at 60fps
- Make reference comparison interface clear and actionable

### Data Storage
- Design schema for recordings, transcriptions, pitch data, and metadata
- Consider CloudKit for sync across devices
- Implement efficient audio file management

### Performance
- Optimize real-time pitch detection to not impact recording
- Cache reference materials locally
- Background process heavy computations

## Dependencies to Research
- [x] Ruby text: ~~Core Text CTRubyAnnotation API~~ → SwiftUI implementation chosen
- [ ] Pitch detection: TarsosDSP-iOS or custom implementation
- [ ] Translation: Apple Translation framework requirements
- [ ] Karaoke timing: AVSpeechSynthesizer boundary detection
- [ ] Pitch accent data: OJAD API or downloadable dictionary