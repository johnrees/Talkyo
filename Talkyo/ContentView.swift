//
//  ContentView.swift
//  Talkyo
//
//  Created by John Rees on 8/2/25.
//

import SwiftUI

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

// MARK: - Main View

struct ContentView: View {
    @StateObject private var transcriptionService = TranscriptionService()
    @State private var isRecording = false
    @State private var selectedMode = SpeechRecognitionMode.onDevice
    
    var body: some View {
        VStack(spacing: 20) {
            recognitionModeSelector
                .padding(.top, 20)
            
            TranscriptionDisplay(
                transcribedText: transcriptionService.transcribedText,
                furiganaText: transcriptionService.furiganaText,
                furiganaTokens: transcriptionService.furiganaTokens,
                processingTime: transcriptionService.transcriptionTime
            )
            
            Spacer()
            
            controlButtons
                .padding(.bottom, 50)
        }
    }
    
    // MARK: - View Components
    
    private var recognitionModeSelector: some View {
        VStack(spacing: 10) {
            Text("Recognition Mode")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Picker("Mode", selection: $selectedMode) {
                ForEach(SpeechRecognitionMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: selectedMode) { _, newValue in
                transcriptionService.setRecognitionMode(newValue)
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
            
            RecordButton(isRecording: $isRecording) {
                handleRecordingToggle()
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleRecordingToggle() {
        if isRecording {
            transcriptionService.startRecording()
        } else {
            transcriptionService.stopRecording()
        }
    }
}

// MARK: - Transcription Display

struct TranscriptionDisplay: View {
    let transcribedText: String
    let furiganaText: String
    let furiganaTokens: [FuriganaToken]
    let processingTime: String
    
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
    }
    
    private var placeholderView: some View {
        Text(placeholderText)
            .font(.title2)
            .foregroundColor(.secondary)
            .padding()
    }
    
    private var transcriptionContent: some View {
        VStack(spacing: 12) {
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
                
                if !furiganaText.isEmpty {
                    Text(furiganaText)
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
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
}

// MARK: - Record Button

struct RecordButton: View {
    @Binding var isRecording: Bool
    let action: () -> Void
    
    private let buttonSize: CGFloat = 120
    private let iconSize: CGFloat = 50
    
    var body: some View {
        Button(action: {}) {
            recordButtonContent
        }
        .simultaneousGesture(pushToTalkGesture)
    }
    
    private var recordButtonContent: some View {
        Image(systemName: isRecording ? "mic.fill" : "mic")
            .font(.system(size: iconSize))
            .foregroundColor(.white)
            .frame(width: buttonSize, height: buttonSize)
            .background(recordingBackground)
            .clipShape(Circle())
            .scaleEffect(isRecording ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isRecording)
    }
    
    private var recordingBackground: Color {
        isRecording ? .red : .blue
    }
    
    private var pushToTalkGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if !isRecording {
                    isRecording = true
                    action()
                }
            }
            .onEnded { _ in
                if isRecording {
                    isRecording = false
                    action()
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