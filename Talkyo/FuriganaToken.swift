//
//  FuriganaToken.swift
//  Talkyo
//
//  Represents a text segment with its furigana reading
//

import Foundation

// MARK: - Furigana Token

/// A data structure representing a segment of Japanese text with its optional furigana (hiragana) reading
struct FuriganaToken: Equatable {
    /// The base text (may contain kanji, hiragana, katakana, or other characters)
    let text: String
    
    /// The hiragana reading of the text (nil if no reading is needed)
    let reading: String?
    
    /// Determines if this token needs furigana display above it
    /// Returns true if:
    /// - There is a reading available
    /// - The reading differs from the base text
    /// - The text contains kanji characters (katakana excluded)
    var needsFurigana: Bool {
        guard let reading = reading else { return false }
        return reading != text && containsKanji
    }
    
    // MARK: - Private Properties
    
    /// Checks if the text contains any kanji characters
    private var containsKanji: Bool {
        text.contains { character in
            isKanji(character)
        }
    }
    
    /// Checks if the text contains any kanji or katakana characters
    private var containsKanjiOrKatakana: Bool {
        text.contains { character in
            isKanji(character) || isKatakana(character)
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