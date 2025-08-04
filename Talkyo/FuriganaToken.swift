//
//  FuriganaToken.swift
//  Talkyo
//
//  Represents a text segment with its furigana reading
//

import Foundation

struct FuriganaToken: Equatable {
    let text: String
    let reading: String?
    
    var needsFurigana: Bool {
        guard let reading = reading else { return false }
        return reading != text && containsKanjiOrKatakana
    }
    
    private var containsKanjiOrKatakana: Bool {
        text.contains { character in
            isKanji(character) || isKatakana(character)
        }
    }
    
    private func isKanji(_ character: Character) -> Bool {
        guard let unicodeScalar = character.unicodeScalars.first else {
            return false
        }
        let kanjiRange = 0x4E00...0x9FFF
        return kanjiRange.contains(Int(unicodeScalar.value))
    }
    
    private func isKatakana(_ character: Character) -> Bool {
        guard let unicodeScalar = character.unicodeScalars.first else {
            return false
        }
        let katakanaRange = 0x30A0...0x30FF
        return katakanaRange.contains(Int(unicodeScalar.value))
    }
}