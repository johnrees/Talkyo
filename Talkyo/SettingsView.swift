//
//  SettingsView.swift
//  Talkyo
//
//  Created by Claude on 8/6/25.
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
                VStack(spacing: 20) {
                    transcriptionModeSelector
                    recognitionModeSelector
                }
                .padding(.top, 30)
                
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
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("Transcription Mode")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Choose how transcription is performed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Picker("Mode", selection: $transcriptionMode) {
                ForEach(TranscriptionMode.allCases, id: \.self) { mode in
                    VStack(alignment: .center, spacing: 4) {
                        Text(mode.rawValue)
                            .font(.system(size: 16, weight: .medium))
                        Text(mode.description)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: transcriptionMode) { _, newValue in
                transcriptionService.setTranscriptionMode(newValue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var recognitionModeSelector: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("Recognition Mode")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Choose speech processing method")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Picker("Mode", selection: $selectedMode) {
                ForEach(SpeechRecognitionMode.allCases, id: \.self) { mode in
                    VStack(alignment: .center, spacing: 4) {
                        Text(mode.rawValue)
                            .font(.system(size: 16, weight: .medium))
                        Text(mode.subtitle)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: selectedMode) { _, newValue in
                transcriptionService.setRecognitionMode(newValue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

#Preview {
    SettingsView(
        selectedMode: .constant(.onDevice),
        transcriptionMode: .constant(.standard),
        transcriptionService: TranscriptionService()
    )
}