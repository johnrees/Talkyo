//
//  ContentView.swift
//  Talkyo
//
//  Created by John Rees on 8/2/25.
//

import SwiftUI
import Translation

// MARK: - Speech Recognition Configuration

enum SpeechRecognitionMode: String, CaseIterable {
    case onDevice = "On-Device"
    case server = "Server"
    case hybrid = "Hybrid"
    
    var subtitle: String {
        switch self {
        case .onDevice: return "Faster, Private"
        case .server: return "More Accurate"
        case .hybrid: return "Best Available"
        }
    }
}

// MARK: - Transcription Mode

enum TranscriptionMode: String, CaseIterable {
    case standard = "Standard"
    case live = "Live"
    
    var description: String {
        switch self {
        case .standard: return "Process after recording"
        case .live: return "Real-time transcription"
        }
    }
}

// MARK: - Main View

struct ContentView: View {
    @StateObject private var transcriptionService = TranscriptionService()
    @State private var isRecording = false
    @State private var selectedMode = SpeechRecognitionMode.onDevice
    @State private var transcriptionMode = TranscriptionMode.standard
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TranscriptionDisplay(
                    transcribedText: transcriptionService.transcribedText,
                    furiganaTokens: transcriptionService.furiganaTokens,
                    processingTime: transcriptionService.transcriptionTime,
                    isLiveMode: transcriptionMode == .live,
                    isRecording: isRecording
                )
                
                Spacer()
                
                controlButtons
                    .padding(.bottom, 50)
            }
            .navigationTitle("Talkyo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(
                    selectedMode: $selectedMode,
                    transcriptionMode: $transcriptionMode,
                    transcriptionService: transcriptionService
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - View Components
    
    private var controlButtons: some View {
        VStack(spacing: 16) {
            if transcriptionService.hasRecording {
                PlaybackButton {
                    transcriptionService.playRecording()
                }
            }
            
            RecordButton(
                isRecording: $isRecording,
                startAction: {
                    transcriptionService.startRecording()
                },
                stopAction: {
                    transcriptionService.stopRecording()
                },
                cancelAction: {
                    transcriptionService.cancelRecording()
                }
            )
        }
    }
    
}

// MARK: - Translation View

struct TranslationView: View {
    let textToTranslate: String
    @State private var translatedText = ""
    @State private var configuration: TranslationSession.Configuration?
    
    private var deviceLanguage: String {
        // Get the device's preferred language with region if available
        let language = Locale.current.language
        
        // Try to get full identifier (e.g., "en-GB")
        if let region = language.region?.identifier {
            return "\(language.languageCode?.identifier ?? "en")-\(region)"
        }
        
        // Fall back to just language code
        return language.languageCode?.identifier ?? "en"
    }
    
    private var shouldTranslate: Bool {
        // Don't translate if device language is Japanese
        return !deviceLanguage.starts(with: "ja")
    }
    
    init(textToTranslate: String) {
        self.textToTranslate = textToTranslate
        print("TranslationView: Initialized with text '\(textToTranslate)'")
    }
    
    var body: some View {
        Group {
            if shouldTranslate {
                VStack(spacing: 8) {
                    Divider()
                        .padding(.horizontal, 40)
                    
                    if !translatedText.isEmpty {
                        Text(translatedText)
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    } else {
                        Text("Translating...")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
            }
        }
        .onAppear {
            print("TranslationView: onAppear called for '\(textToTranslate)'")
            print("TranslationView: Device language is '\(deviceLanguage)', shouldTranslate: \(shouldTranslate)")
            
            if shouldTranslate && !textToTranslate.isEmpty && !textToTranslate.starts(with: "Error:") {
                print("Translation: Creating configuration for '\(textToTranslate)'")
                
                // Use device's current language as target
                let targetLanguage = Locale.Language(identifier: deviceLanguage)
                
                configuration = TranslationSession.Configuration(
                    source: Locale.Language(identifier: "ja"),
                    target: targetLanguage
                )
            }
        }
        .translationTask(configuration) { session in
            print("Translation: Task triggered for '\(textToTranslate)'")
            
            guard !textToTranslate.isEmpty,
                  !textToTranslate.starts(with: "Error:") else {
                print("Translation: Skipping - invalid text")
                return
            }
            
            do {
                print("Translation: Starting translation")
                let response = try await session.translate(textToTranslate)
                print("Translation: Success - '\(response.targetText)'")
                
                await MainActor.run {
                    self.translatedText = response.targetText
                }
            } catch {
                print("Translation error: \(error)")
            }
        }
    }
}

// MARK: - Transcription Display

struct TranscriptionDisplay: View {
    let transcribedText: String
    let furiganaTokens: [FuriganaToken]
    let processingTime: String
    let isLiveMode: Bool
    let isRecording: Bool
    
    private let placeholderText = "話してください"
    
    @State private var translationAvailable = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if transcribedText.isEmpty {
                    placeholderView
                } else {
                    transcriptionContent
                }
                
                if !processingTime.isEmpty {
                    performanceIndicator
                }
            }
            .padding(.vertical)
            .frame(maxWidth: .infinity, minHeight: 200)
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
        .onAppear {
            checkTranslationAvailability()
        }
    }
    
    private var placeholderView: some View {
        Text(placeholderText)
            .font(.title2)
            .foregroundColor(.secondary)
            .padding()
    }
    
    private var transcriptionContent: some View {
        VStack(spacing: 20) {
            // Japanese text with furigana
            if !furiganaTokens.isEmpty {
                // Ruby text display with furigana above kanji
                FuriganaTextView(
                    tokens: furiganaTokens,
                    fontSize: 32,
                    textColor: .primary
                )
                .padding(.horizontal)
            } else {
                // Fallback to original display if no tokens
                Text(transcribedText)
                    .font(.system(size: 32))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // English translation - only show when not recording
            if !isRecording && translationAvailable && !transcribedText.isEmpty && !transcribedText.starts(with: "Error:") {
                let _ = print("TranscriptionDisplay: Showing TranslationView for '\(transcribedText)'")
                TranslationView(textToTranslate: transcribedText)
                    .id(transcribedText) // Force recreation when text changes
            } else if !isRecording && !transcribedText.isEmpty && !translationAvailable {
                VStack(spacing: 8) {
                    Divider()
                        .padding(.horizontal, 40)
                    
                    Text("Translation not available - Language packs may need to be downloaded")
                        .font(.system(size: 14))
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
        }
    }
    
    private var performanceIndicator: some View {
        Text(processingTime)
            .font(.caption)
            .foregroundColor(.blue)
            .padding(.top, 4)
    }
    
    private func checkTranslationAvailability() {
        Task {
            // Get device language with region
            let language = Locale.current.language
            let deviceLanguageCode = language.languageCode?.identifier ?? "en"
            
            // Build full language identifier with region if available
            let fullLanguageIdentifier: String
            if let region = language.region?.identifier {
                fullLanguageIdentifier = "\(deviceLanguageCode)-\(region)"
            } else {
                fullLanguageIdentifier = deviceLanguageCode
            }
            
            // Skip translation availability check if device is in Japanese
            if deviceLanguageCode == "ja" {
                print("TranscriptionDisplay: Device is in Japanese, skipping translation")
                await MainActor.run {
                    translationAvailable = false
                }
                return
            }
            
            let availability = LanguageAvailability()
            
            print("TranscriptionDisplay: Checking translation availability for device language: \(fullLanguageIdentifier)")
            
            // Check availability for device's language with region
            var status = await availability.status(
                from: Locale.Language(identifier: "ja"),
                to: Locale.Language(identifier: fullLanguageIdentifier)
            )
            
            // If not installed, try without region
            if status != .installed && fullLanguageIdentifier.contains("-") {
                print("TranscriptionDisplay: Trying without region: \(deviceLanguageCode)")
                status = await availability.status(
                    from: Locale.Language(identifier: "ja"),
                    to: Locale.Language(identifier: deviceLanguageCode)
                )
            }
            
            await MainActor.run {
                if status == .installed {
                    translationAvailable = true
                    print("Translation: Language '\(deviceLanguageCode)' is installed: \(status)")
                    print("TranscriptionDisplay: translationAvailable set to true")
                } else {
                    translationAvailable = false
                    print("Translation: Language '\(deviceLanguageCode)' is not installed: \(status)")
                    print("TranscriptionDisplay: translationAvailable set to false")
                }
            }
        }
    }
    
}

// MARK: - Record Button

struct RecordButton: View {
    @Binding var isRecording: Bool
    let startAction: () -> Void
    let stopAction: () -> Void
    let cancelAction: () -> Void
    
    private let buttonSize: CGFloat = 120
    private let iconSize: CGFloat = 50
    private let cancelThreshold: CGFloat = 100
    @State private var stopTimer: Timer?
    @State private var isDraggingToCancel = false
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        Button(action: {}) {
            recordButtonContent
        }
        .simultaneousGesture(pushToTalkGesture)
    }
    
    private var recordButtonContent: some View {
        Image(systemName: buttonIcon)
            .font(.system(size: iconSize))
            .foregroundColor(.white)
            .frame(width: buttonSize, height: buttonSize)
            .background(recordingBackground)
            .clipShape(Circle())
            .scaleEffect(isRecording ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isRecording)
            .animation(.easeInOut(duration: 0.15), value: isDraggingToCancel)
    }
    
    private var buttonIcon: String {
        if isDraggingToCancel {
            return "xmark.circle.fill"
        } else {
            return isRecording ? "mic.fill" : "mic"
        }
    }
    
    private var recordingBackground: Color {
        if isDraggingToCancel {
            return .orange
        } else {
            return isRecording ? .red : .blue
        }
    }
    
    private var pushToTalkGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                stopTimer?.invalidate()
                stopTimer = nil
                
                if !isRecording {
                    isRecording = true
                    isDraggingToCancel = false
                    startAction()
                } else {
                    // Check if dragged far enough to trigger cancel
                    let distance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                    isDraggingToCancel = distance > cancelThreshold
                    dragOffset = value.translation
                }
            }
            .onEnded { value in
                if isRecording {
                    let distance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                    let shouldCancel = distance > cancelThreshold
                    
                    if shouldCancel {
                        // Cancel the recording
                        isRecording = false
                        isDraggingToCancel = false
                        dragOffset = .zero
                        cancelAction()
                    } else {
                        // Normal stop with delay
                        isDraggingToCancel = false
                        dragOffset = .zero
                        stopTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
                            isRecording = false
                            stopAction()
                        }
                    }
                }
            }
    }
}

// MARK: - Playback Button

struct PlaybackButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label("Play Recording", systemImage: "play.circle.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.green)
                .cornerRadius(20)
        }
    }
}

#Preview {
    ContentView()
}