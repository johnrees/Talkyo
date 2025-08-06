//
//  PitchAccentDemo.swift
//  Talkyo
//
//  Demo view for testing pitch accent functionality
//

import SwiftUI

// MARK: - Pitch Accent Demo View

/// Demo view to test pitch accent markings with various Japanese words
struct PitchAccentDemo: View {
    @State private var selectedSample = 0
    
    private let sampleTexts = [
        "こんにちは", // Flat (heiban)
        "ありがとう", // Flat  
        "よろしくお願いします", // Accent on 5th mora
        "おはようございます", // Accent on 5th mora
        "日本", // Flat
        "勉強", // Flat
        "大きい", // Flat
        "小さい", // Accent on 2nd mora
        "いち", // Accent on 1st mora (atamadaka)
        "学校" // Flat
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 10) {
                        Text("Pitch Accent Demo")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Blue lines = High pitch • Red lines = Low pitch")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Sample text picker
                    Picker("Sample Text", selection: $selectedSample) {
                        ForEach(0..<sampleTexts.count, id: \.self) { index in
                            Text(sampleTexts[index])
                                .tag(index)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    // Current sample display
                    let currentText = sampleTexts[selectedSample]
                    let tokens = FuriganaGenerator.generateTokens(for: currentText)
                    
                    VStack(spacing: 20) {
                        // Large display
                        FuriganaTextView(
                            tokens: tokens,
                            fontSize: 32,
                            textColor: .primary
                        )
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        
                        // Medium display
                        FuriganaTextView(
                            tokens: tokens,
                            fontSize: 24,
                            textColor: .primary
                        )
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                        
                        // Small display
                        FuriganaTextView(
                            tokens: tokens,
                            fontSize: 18,
                            textColor: .primary
                        )
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Debug information
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Debug Information")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ForEach(Array(tokens.enumerated()), id: \.offset) { index, token in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Token \(index + 1): '\(token.text)'")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                
                                if let reading = token.reading {
                                    Text("Reading: \(reading)")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                }
                                
                                if let pitchAccent = token.pitchAccent {
                                    Text("Accent: Position \(pitchAccent.accentPosition)")
                                        .font(.caption2)
                                        .foregroundColor(.green)
                                    
                                    if let pattern = token.pitchPattern {
                                        Text("Pattern: \(pattern.map(String.init).joined(separator: "-"))")
                                            .font(.caption2)
                                            .foregroundColor(.orange)
                                    }
                                } else {
                                    Text("No pitch accent data")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Pitch Accent")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Preview

#Preview {
    PitchAccentDemo()
}