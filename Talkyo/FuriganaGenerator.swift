//
//  FuriganaGenerator.swift
//  Talkyo
//
//  Generates furigana (hiragana readings) for Japanese text
//

import Foundation

struct FuriganaGenerator {
    static func generate(for text: String) -> String {
        // Skip if no kanji or katakana
        guard text.contains(where: { isKanji($0) || isKatakana($0) }) else {
            return ""
        }
        
        // Use Japanese tokenizer for proper readings
        let tokenizer = CFStringTokenizerCreate(
            kCFAllocatorDefault,
            text as CFString,
            CFRangeMake(0, text.count),
            kCFStringTokenizerUnitWord,
            Locale(identifier: "ja_JP") as CFLocale
        )
        
        var furigana = ""
        var tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)
        
        while tokenType != [] {
            if let latin = CFStringTokenizerCopyCurrentTokenAttribute(
                tokenizer,
                kCFStringTokenizerAttributeLatinTranscription
            ) as? String {
                // Convert romaji to hiragana
                let hiragana = NSMutableString(string: latin)
                CFStringTransform(hiragana, nil, kCFStringTransformLatinHiragana, false)
                furigana += hiragana as String
            }
            tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)
        }
        
        // Don't show furigana if it's the same as the original text
        return furigana == text ? "" : furigana
    }
    
    private static func isKanji(_ char: Character) -> Bool {
        guard let scalar = char.unicodeScalars.first else { return false }
        return (0x4E00...0x9FFF).contains(Int(scalar.value))
    }
    
    private static func isKatakana(_ char: Character) -> Bool {
        guard let scalar = char.unicodeScalars.first else { return false }
        return (0x30A0...0x30FF).contains(Int(scalar.value))
    }
}