//
//  ContentView.swift
//  Talkyo
//
//  Created by John Rees on 8/2/25.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var transcriptionManager = TranscriptionManager()
    @State private var isRecording = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Japanese Voice Transcription")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 50)
            
            // Always show model status for debugging
            Text("Model Status: \(transcriptionManager.modelStatus)")
                .font(.caption)
                .foregroundColor(transcriptionManager.isModelLoaded ? .green : .orange)
                .padding(.horizontal)
            
            ScrollView {
                if transcriptionManager.transcribedText.isEmpty {
                    Text("話してください")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .padding()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    // For now, just show the plain text
                    // Furigana rendering in SwiftUI is complex
                    VStack(spacing: 5) {
                        Text(transcriptionManager.transcribedText)
                            .font(.system(size: 32))
                            .multilineTextAlignment(.center)
                        
                        if !transcriptionManager.furiganaText.isEmpty {
                            Text(transcriptionManager.furiganaText)
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        
                        if !transcriptionManager.transcriptionTime.isEmpty {
                            Text(transcriptionManager.transcriptionTime)
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.top, 5)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 200)
                }
            }
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal)
            
            Spacer()
            
            // Playback button
            if !transcriptionManager.transcribedText.isEmpty {
                Button(action: {
                    transcriptionManager.playRecordedAudio()
                }) {
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
                .padding(.bottom, 20)
            }
            
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
                            startRecording()
                        }
                    }
                    .onEnded { _ in
                        if isRecording {
                            stopRecording()
                        }
                    }
            )
            .padding(.bottom, 50)
        }
        .onAppear {
            transcriptionManager.setupAudioSession()
        }
    }
    
    private func startRecording() {
        isRecording = true
        transcriptionManager.startRecording()
    }
    
    private func stopRecording() {
        isRecording = false
        transcriptionManager.stopRecording()
    }
}

#Preview {
    ContentView()
}
