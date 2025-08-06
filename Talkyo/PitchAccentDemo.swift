//
//  PitchAccentDemo.swift
//  Talkyo
//
//  Demo and testing utilities for pitch accent functionality
//

import Foundation
import SwiftUI

// MARK: - Pitch Accent Demo

/// Demo view for testing pitch accent functionality
struct PitchAccentDemo: View {
    let testPhrases = [
        "こんにちは",
        "ありがとうございます", 
        "よろしくお願いします",
        "おはようございます",
        "すみません"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Pitch Accent Demo")
                    .font(.title)
                    .padding()
                
                ForEach(testPhrases, id: \.self) { phrase in
                    let tokens = FuriganaGenerator.generateTokens(for: phrase)
                    
                    VStack(spacing: 8) {
                        Text("Original: \(phrase)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        FuriganaTextView(
                            tokens: tokens,
                            fontSize: 24,
                            textColor: .primary
                        )
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        
                        // Debug info
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(Array(tokens.enumerated()), id: \.offset) { index, token in
                                HStack {
                                    Text("Token \(index + 1):")
                                        .font(.caption2)
                                        .bold()
                                    
                                    Text(token.text)
                                        .font(.caption2)
                                    
                                    if let reading = token.reading {
                                        Text("(\(reading))")
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                    }
                                    
                                    if let pattern = token.pitchPattern {
                                        Text("Pitch: \(pattern.pitches.map(String.init).joined())")
                                            .font(.caption2)
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color(.systemGray5))
                        .cornerRadius(4)
                    }
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 50)
            }
        }
    }
}

// MARK: - Testing Utilities

enum PitchAccentTesting {
    
    /// Test function to verify pitch accent lookup works correctly
    static func runTests() -> String {
        var results: [String] = []
        results.append("=== Pitch Accent Testing ===")
        results.append("")
        
        let testWords = [
            "こんにちは",
            "ありがとう", 
            "よろしく",
            "はい",
            "いいえ",
            "unknown_word"
        ]
        
        for word in testWords {
            results.append("Testing: \(word)")
            
            let tokens = FuriganaGenerator.generateTokens(for: word)
            
            for (index, token) in tokens.enumerated() {
                var tokenInfo = "  Token \(index + 1): '\(token.text)'"
                
                if let reading = token.reading {
                    tokenInfo += " reading: '\(reading)'"
                }
                
                if let pattern = token.pitchPattern {
                    tokenInfo += " pitch: \(pattern.pitches)"
                    tokenInfo += " accent: \(pattern.accentPosition)"
                    tokenInfo += " confidence: \(pattern.confidence)"
                } else {
                    tokenInfo += " (no pitch data)"
                }
                
                results.append(tokenInfo)
            }
            results.append("")
        }
        
        // Database statistics
        results.append("Database Statistics:")
        results.append("  Total entries: \(PitchAccentService.databaseSize)")
        results.append("  Sample entries: \(PitchAccentService.allReadings.prefix(10).joined(separator: ", "))")
        
        return results.joined(separator: "\n")
    }
}

#Preview {
    PitchAccentDemo()
}