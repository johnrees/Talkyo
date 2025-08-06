//
//  SettingsView.swift
//  Talkyo
//

import SwiftUI

struct SettingsView: View {
    @Binding var selectedMode: SpeechRecognitionMode
    @Binding var transcriptionMode: TranscriptionMode
    @ObservedObject var transcriptionService: TranscriptionService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 16) {
                    transcriptionModeSelector
                    recognitionModeSelector
                }
                .padding(.top, 40)
                
                Spacer()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var transcriptionModeSelector: some View {
        VStack(spacing: 10) {
            Text("Transcription Mode")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Picker("Mode", selection: $transcriptionMode) {
                ForEach(TranscriptionMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .accessibilityIdentifier("transcriptionModeSelector")
            .onChange(of: transcriptionMode) { _, newValue in
                transcriptionService.setTranscriptionMode(newValue)
            }
        }
    }
    
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
            .accessibilityIdentifier("recognitionModeSelector")
            .onChange(of: selectedMode) { _, newValue in
                transcriptionService.setRecognitionMode(newValue)
            }
        }
    }
}