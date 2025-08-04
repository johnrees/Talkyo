//
//  FuriganaGenerator.swift
//  Talkyo
//
//  Generates furigana (hiragana readings) for Japanese text
//

import Foundation

// MARK: - Furigana Generator

enum FuriganaGenerator {
    // MARK: - Public Methods
    
    static func generate(for text: String) -> String {
        // Skip processing if text contains no kanji or katakana
        guard textRequiresFurigana(text) else {
            return ""
        }
        
        let furiganaText = generateFuriganaText(from: text)
        
        // Don't show furigana if it's identical to the original
        return furiganaText == text ? "" : furiganaText
    }
    
    static func generateTokens(for text: String) -> [FuriganaToken] {
        let tokenizer = createJapaneseTokenizer(for: text)
        var tokens: [FuriganaToken] = []
        
        var tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)
        
        while tokenType != [] {
            let range = CFStringTokenizerGetCurrentTokenRange(tokenizer)
            let startIndex = text.index(text.startIndex, offsetBy: range.location)
            let endIndex = text.index(startIndex, offsetBy: range.length)
            let tokenText = String(text[startIndex..<endIndex])
            
            let reading = extractHiraganaReading(from: tokenizer)
            tokens.append(FuriganaToken(text: tokenText, reading: reading))
            
            tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)
        }
        
        return tokens
    }
    
    // MARK: - Private Methods
    
    private static func textRequiresFurigana(_ text: String) -> Bool {
        text.contains { character in
            isKanji(character) || isKatakana(character)
        }
    }
    
    private static func generateFuriganaText(from text: String) -> String {
        let tokens = generateTokens(for: text)
        return tokens.compactMap { $0.reading ?? $0.text }.joined()
    }
    
    private static func createJapaneseTokenizer(for text: String) -> CFStringTokenizer {
        CFStringTokenizerCreate(
            kCFAllocatorDefault,
            text as CFString,
            CFRangeMake(0, text.count),
            kCFStringTokenizerUnitWord,
            Locale(identifier: "ja_JP") as CFLocale
        )
    }
    
    private static func extractHiraganaReading(from tokenizer: CFStringTokenizer) -> String? {
        guard let latinReading = CFStringTokenizerCopyCurrentTokenAttribute(
            tokenizer,
            kCFStringTokenizerAttributeLatinTranscription
        ) as? String else {
            return nil
        }
        
        // Convert romaji to hiragana
        let hiraganaReading = NSMutableString(string: latinReading)
        CFStringTransform(hiraganaReading, nil, kCFStringTransformLatinHiragana, false)
        
        return hiraganaReading as String
    }
    
    // MARK: - Character Classification
    
    private static func isKanji(_ character: Character) -> Bool {
        guard let unicodeScalar = character.unicodeScalars.first else {
            return false
        }
        
        let kanjiRange = 0x4E00...0x9FFF
        return kanjiRange.contains(Int(unicodeScalar.value))
    }
    
    private static func isKatakana(_ character: Character) -> Bool {
        guard let unicodeScalar = character.unicodeScalars.first else {
            return false
        }
        
        let katakanaRange = 0x30A0...0x30FF
        return katakanaRange.contains(Int(unicodeScalar.value))
    }
}