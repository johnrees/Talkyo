//
//  FuriganaToken.swift
//  Talkyo
//
//  Represents a text segment with its furigana reading and pitch accent pattern
//

import Foundation

// MARK: - Pitch Accent Pattern

/// Represents the pitch accent pattern for a Japanese word or phrase
struct PitchAccentPattern: Equatable {
    /// Array of pitch values (0 = low, 1 = high) for each mora
    let pitches: [Int]
    
    /// The accent kernel position (where pitch drops from high to low)
    /// 0 means no accent (flat), 1-n indicates position of accent
    let accentPosition: Int
    
    /// Confidence level of this pitch accent data (0.0 to 1.0)
    let confidence: Double
    
    init(pitches: [Int], accentPosition: Int = 0, confidence: Double = 1.0) {
        self.pitches = pitches
        self.accentPosition = accentPosition
        self.confidence = confidence
    }
    
    /// Returns true if this pattern has pitch accent information
    var hasPitchData: Bool {
        return !pitches.isEmpty && confidence > 0.0
    }
}

// MARK: - Furigana Token

/// A data structure representing a segment of Japanese text with its optional furigana (hiragana) reading and pitch accent
struct FuriganaToken: Equatable {
    /// The base text (may contain kanji, hiragana, katakana, or other characters)
    let text: String
    
    /// The hiragana reading of the text (nil if no reading is needed)
    let reading: String?
    
    /// The pitch accent pattern for this token
    let pitchPattern: PitchAccentPattern?
    
    /// Determines if this token needs furigana display above it
    /// Returns true if:
    /// - There is a reading available
    /// - The reading differs from the base text
    /// - The text contains kanji characters (not katakana)
    var needsFurigana: Bool {
        guard let reading = reading else { return false }
        return reading != text && containsKanji
    }
    
    /// Determines if this token has pitch accent information to display
    var hasPitchAccent: Bool {
        return pitchPattern?.hasPitchData == true
    }
    
    /// Convenience initializer for tokens without pitch accent data
    init(text: String, reading: String?) {
        self.text = text
        self.reading = reading
        self.pitchPattern = nil
    }
    
    /// Full initializer with pitch accent data
    init(text: String, reading: String?, pitchPattern: PitchAccentPattern?) {
        self.text = text
        self.reading = reading
        self.pitchPattern = pitchPattern
    }
    
    // MARK: - Private Properties
    
    /// Checks if the text contains any kanji characters
    private var containsKanji: Bool {
        text.contains { character in
            isKanji(character)
        }
    }
    
    // MARK: - Private Methods
    
    /// Determines if a character is a kanji character
    /// - Parameter character: The character to check
    /// - Returns: true if the character is in the kanji Unicode range
    private func isKanji(_ character: Character) -> Bool {
        guard let unicodeScalar = character.unicodeScalars.first else {
            return false
        }
        let kanjiRange = 0x4E00...0x9FFF
        return kanjiRange.contains(Int(unicodeScalar.value))
    }
    
    /// Determines if a character is a katakana character
    /// - Parameter character: The character to check
    /// - Returns: true if the character is in the katakana Unicode range
    private func isKatakana(_ character: Character) -> Bool {
        guard let unicodeScalar = character.unicodeScalars.first else {
            return false
        }
        let katakanaRange = 0x30A0...0x30FF
        return katakanaRange.contains(Int(unicodeScalar.value))
    }
}