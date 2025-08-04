//
//  ContentView.swift
//  Talkyo
//
//  Created by John Rees on 8/2/25.
//

import SwiftUI

enum TranscriptionEngine: String, CaseIterable {
    case whisper = "Whisper"
    case coreML = "Core ML"
}

enum WhisperModelSize: String, CaseIterable {
    case tiny = "tiny"
    case base = "base"
    case small = "small"
    
    var displayName: String {
        switch self {
        case .tiny: return "Tiny (39M)"
        case .base: return "Base (74M)"
        case .small: return "Small (244M)"
        }
    }
}

enum CoreMLConfiguration: String, CaseIterable {
    case onDevice = "On-Device"
    case server = "Server"
    case hybrid = "Hybrid"
    
    var description: String {
        switch self {
        case .onDevice: return "Faster, Private"
        case .server: return "More Accurate"
        case .hybrid: return "Best Available"
        }
    }
}

struct ContentView: View {
    @StateObject private var transcriptionService = TranscriptionService()
    @State private var isRecording = false
    @State private var selectedEngine = TranscriptionEngine.whisper
    @State private var selectedModelSize = WhisperModelSize.tiny
    @State private var selectedCoreMLConfig = CoreMLConfiguration.onDevice
    
    var body: some View {
        VStack(spacing: 20) {
            Picker("Engine", selection: $selectedEngine) {
                ForEach(TranscriptionEngine.allCases, id: \.self) { engine in
                    Text(engine.rawValue).tag(engine)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.top, 20)
            .onChange(of: selectedEngine) { newValue in
                transcriptionService.setEngine(newValue)
            }
            
            if selectedEngine == .whisper {
                VStack(spacing: 10) {
                    Text("Model Size")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Picker("Model Size", selection: $selectedModelSize) {
                        ForEach(WhisperModelSize.allCases, id: \.self) { size in
                            Text(size.displayName).tag(size)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .onChange(of: selectedModelSize) { newValue in
                        transcriptionService.setWhisperModel(newValue)
                    }
                }
                .transition(.opacity)
            } else if selectedEngine == .coreML {
                VStack(spacing: 10) {
                    Text("Recognition Mode")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Picker("Mode", selection: $selectedCoreMLConfig) {
                        ForEach(CoreMLConfiguration.allCases, id: \.self) { config in
                            Text(config.rawValue).tag(config)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .onChange(of: selectedCoreMLConfig) { newValue in
                        transcriptionService.setCoreMLConfiguration(newValue)
                    }
                }
                .transition(.opacity)
            }
            
            TranscriptionView(
                text: transcriptionService.transcribedText,
                furigana: transcriptionService.furiganaText,
                time: transcriptionService.transcriptionTime
            )
            
            Spacer()
            
            if transcriptionService.hasRecording {
                PlayButton {
                    transcriptionService.playRecording()
                }
            }
            
            #if DEBUG
            Button("Test Ruby Text") {
                transcriptionService.showTestText()
            }
            .foregroundColor(.orange)
            #endif
            
            RecordButton(isRecording: $isRecording) {
                if isRecording {
                    transcriptionService.startRecording()
                } else {
                    transcriptionService.stopRecording()
                }
            }
            .padding(.bottom, 50)
        }
        .animation(.easeInOut(duration: 0.3), value: selectedEngine)
    }
}

struct TranscriptionView: View {
    let text: String
    let furigana: String
    let time: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if text.isEmpty {
                    Text("話してください")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    // For now, show text with furigana in parentheses
                    Text(formatTextWithInlineFurigana(text: text, furigana: furigana))
                        .font(.system(size: 28))
                        .multilineTextAlignment(.center)
                        .padding()
                }
                
                if !time.isEmpty {
                    Text(time)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical)
            .frame(maxWidth: .infinity, minHeight: 200)
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private func formatTextWithInlineFurigana(text: String, furigana: String) -> String {
        guard !furigana.isEmpty else { return text }
        
        // For display, show furigana inline with parentheses
        var result = text
        let components = furigana.components(separatedBy: " ")
        
        for component in components.reversed() {
            if component.contains("(") && component.contains(")") {
                let parts = component.split(separator: "(", maxSplits: 1)
                if parts.count == 2 {
                    let kanji = String(parts[0])
                    let reading = String(parts[1].dropLast())
                    result = result.replacingOccurrences(of: kanji, with: "\(kanji)(\(reading))")
                }
            }
        }
        
        return result
    }
}

struct RecordButton: View {
    @Binding var isRecording: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {}) {
            Image(systemName: isRecording ? "mic.fill" : "mic")
                .font(.system(size: 50))
                .foregroundColor(.white)
                .frame(width: 120, height: 120)
                .background(isRecording ? Color.red : Color.blue)
                .clipShape(Circle())
                .scaleEffect(isRecording ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isRecording)
        }
        .simultaneousGesture(
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
        )
    }
}

struct PlayButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "play.circle.fill")
                Text("Play Recording")
            }
            .font(.system(size: 16))
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