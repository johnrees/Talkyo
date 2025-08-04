//
//  ContentView.swift
//  Talkyo
//
//  Created by John Rees on 8/2/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var transcriptionService = TranscriptionService()
    @State private var isRecording = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Japanese Voice Transcription")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 50)
            
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
            VStack(spacing: 5) {
                if text.isEmpty {
                    Text("話してください")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    Text(text)
                        .font(.system(size: 32))
                        .multilineTextAlignment(.center)
                    
                    if !furigana.isEmpty {
                        Text(furigana)
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    
                    if !time.isEmpty {
                        Text(time)
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.top, 5)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 200)
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
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