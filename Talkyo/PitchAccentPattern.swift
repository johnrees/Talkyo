//
//  PitchAccentPattern.swift
//  Talkyo
//
//  Represents pitch accent patterns for Japanese words
//

import Foundation

// MARK: - Pitch Accent Pattern

/// Represents the pitch accent pattern for a Japanese word
struct PitchAccentPattern: Equatable, Codable {
    /// The position where the pitch drops (0 = heiban/flat, 1+ = accent position)
    let accentPosition: Int
    
    /// The reading (kana) this pattern applies to
    let reading: String
    
    /// Additional metadata about the accent pattern
    let metadata: PitchAccentMetadata?
    
    init(accentPosition: Int, reading: String, metadata: PitchAccentMetadata? = nil) {
        self.accentPosition = accentPosition
        self.reading = reading
        self.metadata = metadata
    }
    
    /// Convenience initializer for simple patterns
    init(_ position: Int, reading: String) {
        self.init(accentPosition: position, reading: reading, metadata: nil)
    }
    
    /// Returns true if this is a heiban (flat) accent pattern
    var isHeiban: Bool {
        return accentPosition == 0
    }
    
    /// Returns true if this is an atamadaka (initial-high) accent pattern
    var isAtamadaka: Bool {
        return accentPosition == 1
    }
    
    /// Returns true if this is a nakadaka (mid-drop) or odaka (final-drop) accent pattern
    var hasAccent: Bool {
        return accentPosition > 0
    }
    
    /// Generate pitch pattern array for the reading (1=high, 0=low)
    func generatePitchArray() -> [Int] {
        let moraCount = countMora(in: reading)
        guard moraCount > 0 else { return [] }
        
        if isHeiban {
            // Heiban: low-high-high-high...
            var pattern = Array(repeating: 1, count: moraCount)
            if moraCount > 0 {
                pattern[0] = 0
            }
            return pattern
        } else if accentPosition == 1 {
            // Atamadaka: high-low-low-low...
            var pattern = Array(repeating: 0, count: moraCount)
            if moraCount > 0 {
                pattern[0] = 1
            }
            return pattern
        } else {
            // Nakadaka/Odaka: low-high-high-low... (drop after accent position)
            var pattern = Array(repeating: 1, count: moraCount)
            if moraCount > 0 {
                pattern[0] = 0
            }
            
            // Set pitch to low after the accent position
            for i in accentPosition..<moraCount {
                pattern[i] = 0
            }
            return pattern
        }
    }
    
    /// Count mora in a kana string
    private func countMora(in kana: String) -> Int {
        var count = 0
        var previousWasSmallKana = false
        
        for char in kana {
            if isSmallKana(char) {
                if !previousWasSmallKana {
                    // Small kana combines with previous mora (like きゅ, しょ)
                    previousWasSmallKana = true
                    continue
                }
            } else if isLongVowelMark(char) {
                // Long vowel mark extends previous mora
                continue
            }
            
            count += 1
            previousWasSmallKana = false
        }
        
        return count
    }
    
    /// Check if character is a small kana (っ, ゃ, ゅ, ょ, etc.)
    private func isSmallKana(_ char: Character) -> Bool {
        let smallKana: Set<Character> = ["ぁ", "ぃ", "ぅ", "ぇ", "ぉ", "っ", "ゃ", "ゅ", "ょ", "ゎ",
                                        "ァ", "ィ", "ゥ", "ェ", "ォ", "ッ", "ャ", "ュ", "ョ", "ヮ"]
        return smallKana.contains(char)
    }
    
    /// Check if character is a long vowel mark
    private func isLongVowelMark(_ char: Character) -> Bool {
        return char == "ー" || char == "～"
    }
}

// MARK: - Pitch Accent Metadata

/// Additional metadata for pitch accent patterns
struct PitchAccentMetadata: Equatable, Codable {
    /// JLPT level (if known)
    let jlptLevel: String?
    
    /// Frequency ranking (if available)
    let frequency: Int?
    
    /// Source of the data
    let source: String?
    
    /// Alternative accent patterns (some words have multiple accepted patterns)
    let alternatives: [Int]?
    
    /// Part of speech
    let partOfSpeech: String?
    
    init(jlptLevel: String? = nil, frequency: Int? = nil, source: String? = nil, 
         alternatives: [Int]? = nil, partOfSpeech: String? = nil) {
        self.jlptLevel = jlptLevel
        self.frequency = frequency
        self.source = source
        self.alternatives = alternatives
        self.partOfSpeech = partOfSpeech
    }
}