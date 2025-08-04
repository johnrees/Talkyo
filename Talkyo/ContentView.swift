//
//  ContentView.swift
//  Talkyo
//
//  Created by John Rees on 8/2/25.
//

import SwiftUI

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
    @State private var selectedCoreMLConfig = CoreMLConfiguration.onDevice
    
    var body: some View {
        VStack(spacing: 20) {
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
            .padding(.top, 20)
            
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
    }
}

struct TranscriptionView: View {
    let text: String
    let furigana: String
    let time: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                if text.isEmpty {
                    Text("話してください")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    // Show original text with kanji
                    Text(text)
                        .font(.system(size: 32))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Show kana reading below
                    if !furigana.isEmpty {
                        Text(extractKanaReading(furigana: furigana))
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                
                if !time.isEmpty {
                    Text(time)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.top, 5)
                }
            }
            .padding(.vertical)
            .frame(maxWidth: .infinity, minHeight: 200)
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private func extractKanaReading(furigana: String) -> String {
        // Convert furigana format to full kana reading
        var result = ""
        let components = furigana.components(separatedBy: " ")
        
        for component in components {
            if component.contains("(") && component.contains(")") {
                let parts = component.split(separator: "(", maxSplits: 1)
                if parts.count == 2 {
                    let reading = String(parts[1].dropLast()) // Remove closing parenthesis
                    result += reading
                }
            } else {
                result += component
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