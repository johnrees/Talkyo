import SwiftUI

struct SettingsView: View {
    @Binding var selectedMode: SpeechRecognitionMode
    @Binding var transcriptionMode: TranscriptionMode
    @Binding var debugModeEnabled: Bool
    @AppStorage("audioInterruptionMode") var audioInterruptionMode = "duck"
    let transcriptionService: TranscriptionService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                VStack(spacing: 16) {
                    transcriptionModeSelector
                    recognitionModeSelector
                    audioInterruptionToggle
                    debugModeToggle
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
            .onChange(of: selectedMode) { _, newValue in
                transcriptionService.setRecognitionMode(newValue)
            }
        }
    }
    
    private var audioInterruptionToggle: some View {
        VStack(spacing: 10) {
            Text("Audio Interruption")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Picker("Audio Interruption", selection: $audioInterruptionMode) {
                Text("Duck Audio").tag("duck")
                Text("Pause Audio").tag("pause")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
        }
    }
    
    private var debugModeToggle: some View {
        VStack(spacing: 10) {
            Text("Debug Mode")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Toggle("Show transcription timing", isOn: $debugModeEnabled)
                .toggleStyle(SwitchToggleStyle())
                .padding(.horizontal)
        }
    }
}