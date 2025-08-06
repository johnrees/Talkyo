import SwiftUI
import Translation

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

@MainActor
struct ContentView: View {
    @State private var transcriptionService = TranscriptionService()
    @State private var isRecording = false
    @State private var selectedMode = SpeechRecognitionMode.onDevice
    @State private var transcriptionMode = TranscriptionMode.standard
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TranscriptionDisplay(
                    transcribedText: transcriptionService.transcribedText,
                    furiganaTokens: transcriptionService.furiganaTokens,
                    processingTime: transcriptionService.transcriptionTime,
                    isLiveMode: transcriptionMode == .live,
                    isRecording: isRecording
                )
                .padding(.top, 20)
                
                Spacer()
                
                controlButtons
                    .padding(.bottom, 50)
            }
            .navigationTitle("Talkyo")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
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
    }
    
    private var controlButtons: some View {
        VStack(spacing: 16) {
            if transcriptionService.hasRecording {
                PlaybackButton {
                    transcriptionService.playRecording()
                }
            }
            
            RecordButton(
                isRecording: $isRecording,
                startAction: transcriptionService.startRecording,
                stopAction: transcriptionService.stopRecording,
                cancelAction: transcriptionService.cancelRecording
            )
        }
    }
}

struct TranslationView: View {
    let textToTranslate: String
    @State private var translatedText = ""
    @State private var configuration: TranslationSession.Configuration?
    
    private var deviceLanguage: String {
        let language = Locale.current.language
        if let region = language.region?.identifier {
            return "\(language.languageCode?.identifier ?? "en")-\(region)"
        }
        return language.languageCode?.identifier ?? "en"
    }
    
    private var shouldTranslate: Bool {
        !deviceLanguage.starts(with: "ja")
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
        .task {
            guard shouldTranslate,
                  !textToTranslate.isEmpty,
                  !textToTranslate.starts(with: "Error:") else { return }
            
            let targetLanguage = Locale.Language(identifier: deviceLanguage)
            configuration = TranslationSession.Configuration(
                source: Locale.Language(identifier: "ja"),
                target: targetLanguage
            )
        }
        .translationTask(configuration) { session in
            guard !textToTranslate.isEmpty,
                  !textToTranslate.starts(with: "Error:") else { return }
            
            do {
                let response = try await session.translate(textToTranslate)
                translatedText = response.targetText
            } catch {
                print("Translation error: \(error)")
            }
        }
    }
}

struct TranscriptionDisplay: View {
    let transcribedText: String
    let furiganaTokens: [FuriganaToken]
    let processingTime: String
    let isLiveMode: Bool
    let isRecording: Bool
    @State private var translationAvailable = false
    
    private let placeholderText = "話してください"
    
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
        .task {
            await checkTranslationAvailability()
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
            
            if !isRecording && translationAvailable && !transcribedText.isEmpty && !transcribedText.starts(with: "Error:") {
                TranslationView(textToTranslate: transcribedText)
                    .id(transcribedText)
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
    
    private func checkTranslationAvailability() async {
        let language = Locale.current.language
        let deviceLanguageCode = language.languageCode?.identifier ?? "en"
        
        let fullLanguageIdentifier: String
        if let region = language.region?.identifier {
            fullLanguageIdentifier = "\(deviceLanguageCode)-\(region)"
        } else {
            fullLanguageIdentifier = deviceLanguageCode
        }
        
        guard deviceLanguageCode != "ja" else {
            translationAvailable = false
            return
        }
        
        let availability = LanguageAvailability()
        
        var status = await availability.status(
            from: Locale.Language(identifier: "ja"),
            to: Locale.Language(identifier: fullLanguageIdentifier)
        )
        
        if status != .installed && fullLanguageIdentifier.contains("-") {
            status = await availability.status(
                from: Locale.Language(identifier: "ja"),
                to: Locale.Language(identifier: deviceLanguageCode)
            )
        }
        
        translationAvailable = status == .installed
    }
}

struct RecordButton: View {
    @Binding var isRecording: Bool
    let startAction: () -> Void
    let stopAction: () -> Void
    let cancelAction: () -> Void
    
    @State private var stopTimer: Timer?
    @State private var isDraggingToCancel = false
    @State private var dragOffset: CGSize = .zero
    
    private let buttonSize: CGFloat = 120
    private let iconSize: CGFloat = 50
    private let cancelThreshold: CGFloat = 100
    
    var body: some View {
        recordButtonContent
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
        isDraggingToCancel ? "xmark.circle.fill" : (isRecording ? "mic.fill" : "mic")
    }
    
    private var recordingBackground: Color {
        isDraggingToCancel ? .orange : (isRecording ? .red : .blue)
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
                    let distance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                    isDraggingToCancel = distance > cancelThreshold
                    dragOffset = value.translation
                }
            }
            .onEnded { value in
                if isRecording {
                    let distance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                    let shouldCancel = distance > cancelThreshold
                    
                    isDraggingToCancel = false
                    dragOffset = .zero
                    
                    if shouldCancel {
                        isRecording = false
                        cancelAction()
                    } else {
                        stopTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
                            isRecording = false
                            stopAction()
                        }
                    }
                }
            }
    }
}

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