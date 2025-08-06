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
            
            // Split mixed tokens (kanji + hiragana/katakana) into proper segments
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
    
    /// Split mixed tokens (containing both kanji and hiragana/katakana) into properly aligned segments
    private static func splitMixedToken(text: String, reading: String?) -> [FuriganaToken] {
        guard let reading = reading, !text.isEmpty else {
            return [FuriganaToken(text: text, reading: nil)]
        }
        
        // If token is pure hiragana or katakana, no furigana needed
        if text.allSatisfy({ isHiragana($0) || isKatakana($0) }) {
            return [FuriganaToken(text: text, reading: nil)]
        }
        
        // If token is pure kanji, use the whole reading
        if text.allSatisfy({ isKanji($0) }) {
            return [FuriganaToken(text: text, reading: reading)]
        }
        
        // Handle mixed tokens: split by character type and distribute reading
        return splitMixedTokenByCharacterType(text: text, reading: reading)
    }
    
    /// Split a mixed token containing different character types and distribute the reading appropriately
    private static func splitMixedTokenByCharacterType(text: String, reading: String) -> [FuriganaToken] {
        // Find hiragana/katakana suffixes in the original text and remove them from reading
        let trimmedReading = removeMatchingSuffixFromReading(originalText: text, reading: reading)
        
        var result: [FuriganaToken] = []
        var currentSegment = ""
        var currentType: CharacterType?
        
        for char in text {
            let charType = getCharacterType(char)
            
            // If character type changes, process the accumulated segment
            if let existingType = currentType, existingType != charType {
                let token = createTokenForSegment(
                    text: currentSegment,
                    type: existingType,
                    fullReading: trimmedReading,
                    originalText: text
                )
                result.append(token)
                currentSegment = String(char)
                currentType = charType
            } else {
                currentSegment += String(char)
                currentType = charType
            }
        }
        
        // Process the final segment
        if !currentSegment.isEmpty, let type = currentType {
            let token = createTokenForSegment(
                text: currentSegment,
                type: type,
                fullReading: trimmedReading,
                originalText: text
            )
            result.append(token)
        }
        
        return result
    }
    
    /// Remove hiragana/katakana suffix from reading that matches the original text
    private static func removeMatchingSuffixFromReading(originalText: String, reading: String) -> String {
        // Find the longest hiragana/katakana suffix in the original text
        var suffixLength = 0
        let textArray = Array(originalText)
        
        for i in stride(from: textArray.count - 1, through: 0, by: -1) {
            let char = textArray[i]
            if isHiragana(char) || isKatakana(char) {
                suffixLength += 1
            } else {
                break
            }
        }
        
        // If we found a suffix, remove it from the reading
        if suffixLength > 0 {
            let suffix = String(textArray.suffix(suffixLength))
            if reading.hasSuffix(suffix) {
                return String(reading.dropLast(suffix.count))
            }
        }
        
        return reading
    }
    
    /// Create a token for a specific segment with appropriate reading
    private static func createTokenForSegment(text: String, type: CharacterType, fullReading: String, originalText: String) -> FuriganaToken {
        switch type {
        case .kanji:
            // Kanji gets the available reading (after suffixes are removed)
            return FuriganaToken(text: text, reading: fullReading.isEmpty ? nil : fullReading)
        case .hiragana, .katakana, .other:
            // Hiragana/katakana/other don't need furigana
            return FuriganaToken(text: text, reading: nil)
        }
    }
    
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
    
    /// Character types for Japanese text processing
    private enum CharacterType {
        case kanji
        case hiragana
        case katakana
        case other
    }
    
    /// Determine the character type of a given character
    private static func getCharacterType(_ character: Character) -> CharacterType {
        if isKanji(character) {
            return .kanji
        } else if isHiragana(character) {
            return .hiragana
        } else if isKatakana(character) {
            return .katakana
        } else {
            return .other
        }
    }
    
    private static func isKanji(_ character: Character) -> Bool {
        guard let unicodeScalar = character.unicodeScalars.first else {
            return false
        }
        
        let kanjiRange = 0x4E00...0x9FFF
        return kanjiRange.contains(Int(unicodeScalar.value))
    }
    
    private static func isHiragana(_ character: Character) -> Bool {
        guard let unicodeScalar = character.unicodeScalars.first else {
            return false
        }
        
        let hiraganaRange = 0x3040...0x309F
        return hiraganaRange.contains(Int(unicodeScalar.value))
    }
    
    private static func isKatakana(_ character: Character) -> Bool {
        guard let unicodeScalar = character.unicodeScalars.first else {
            return false
        }
        
        let katakanaRange = 0x30A0...0x30FF
        return katakanaRange.contains(Int(unicodeScalar.value))
    }
}