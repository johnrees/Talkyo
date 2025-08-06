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
        var lastEndIndex = text.startIndex
        
        var tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)
        
        while tokenType != [] {
            let range = CFStringTokenizerGetCurrentTokenRange(tokenizer)
            let startIndex = text.index(text.startIndex, offsetBy: range.location)
            let endIndex = text.index(startIndex, offsetBy: range.length)
            
            // Add any skipped characters (like punctuation) between tokens
            if lastEndIndex < startIndex {
                let skippedText = String(text[lastEndIndex..<startIndex])
                tokens.append(FuriganaToken(text: skippedText, reading: nil))
            }
            
            let tokenText = String(text[startIndex..<endIndex])
            let reading = extractHiraganaReading(from: tokenizer)
            
            // Split tokens with mixed kanji and non-kanji characters for better alignment
            let splitTokens = splitMixedToken(text: tokenText, reading: reading)
            tokens.append(contentsOf: splitTokens)
            
            lastEndIndex = endIndex
            tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)
        }
        
        // Add any remaining characters at the end
        if lastEndIndex < text.endIndex {
            let remainingText = String(text[lastEndIndex..<text.endIndex])
            tokens.append(FuriganaToken(text: remainingText, reading: nil))
        }
        
        return tokens
    }
    
    // MARK: - Private Methods
    
    private static func splitMixedToken(text: String, reading: String?) -> [FuriganaToken] {
        // If the token is purely kanji, hiragana, katakana, or other, return as single token
        let hasKanji = text.contains { isKanji($0) }
        let hasHiragana = text.contains { isHiragana($0) }
        let hasKatakana = text.contains { isKatakana($0) }
        
        // If it's homogeneous or very short, keep as one token
        let characterTypes = [hasKanji, hasHiragana, hasKatakana].filter { $0 }.count
        if characterTypes <= 1 || text.count == 1 {
            return [FuriganaToken(text: text, reading: reading)]
        }
        
        // Split mixed tokens character by character for better alignment
        var tokens: [FuriganaToken] = []
        var currentSegment = ""
        var currentType: CharacterType?
        
        for character in text {
            let charType = getCharacterType(character)
            
            if currentType == charType {
                currentSegment.append(character)
            } else {
                // Finalize current segment
                if !currentSegment.isEmpty {
                    let segmentReading = (currentType == .kanji && reading != nil) ? 
                        getReadingForSegment(currentSegment, from: reading!) : nil
                    tokens.append(FuriganaToken(text: currentSegment, reading: segmentReading))
                }
                
                // Start new segment
                currentSegment = String(character)
                currentType = charType
            }
        }
        
        // Add final segment
        if !currentSegment.isEmpty {
            let segmentReading = (currentType == .kanji && reading != nil) ? 
                getReadingForSegment(currentSegment, from: reading!) : nil
            tokens.append(FuriganaToken(text: currentSegment, reading: segmentReading))
        }
        
        return tokens
    }
    
    private enum CharacterType {
        case kanji, hiragana, katakana, other
    }
    
    private static func getCharacterType(_ character: Character) -> CharacterType {
        if isKanji(character) { return .kanji }
        if isHiragana(character) { return .hiragana }
        if isKatakana(character) { return .katakana }
        return .other
    }
    
    private static func getReadingForSegment(_ segment: String, from fullReading: String) -> String? {
        // For now, return the full reading for kanji segments
        // This could be improved with more sophisticated reading mapping
        return fullReading
    }
    
    private static func textRequiresFurigana(_ text: String) -> Bool {
        text.contains { character in
            isKanji(character)
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
    
    private static func isHiragana(_ character: Character) -> Bool {
        guard let unicodeScalar = character.unicodeScalars.first else {
            return false
        }
        
        let hiraganaRange = 0x3040...0x309F
        return hiraganaRange.contains(Int(unicodeScalar.value))
    }
}