//
//  NumberFormatter.swift
//  Talkyo
//
//  Utility for converting between Arabic numerals and Japanese kanji numbers
//

import Foundation

// MARK: - Number Format

enum NumberFormat: String, CaseIterable {
    case numerals = "Numerals"
    case kanji = "Kanji"
    
    var description: String {
        switch self {
        case .numerals: return "123, 2024"
        case .kanji: return "一二三, 二〇二四"
        }
    }
}

// MARK: - Japanese Number Formatter

enum JapaneseNumberFormatter {
    
    // MARK: - Constants
    
    private static let kanjiDigits = [
        0: "〇", 1: "一", 2: "二", 3: "三", 4: "四",
        5: "五", 6: "六", 7: "七", 8: "八", 9: "九"
    ]
    
    private static let arabicToKanji = [
        "0": "〇", "1": "一", "2": "二", "3": "三", "4": "四",
        "5": "五", "6": "六", "7": "七", "8": "八", "9": "九"
    ]
    
    private static let kanjiToArabic = [
        "〇": "0", "一": "1", "二": "2", "三": "3", "四": "4",
        "五": "5", "六": "6", "七": "7", "八": "8", "九": "9"
    ]
    
    // MARK: - Public Methods
    
    static func convertNumbers(in text: String, to format: NumberFormat) -> String {
        switch format {
        case .numerals:
            return convertKanjiToNumerals(text)
        case .kanji:
            return convertNumeralsToKanji(text)
        }
    }
    
    // MARK: - Private Methods
    
    private static func convertNumeralsToKanji(_ text: String) -> String {
        var result = text
        
        // Replace individual Arabic digits with kanji
        for (arabic, kanji) in arabicToKanji {
            result = result.replacingOccurrences(of: arabic, with: kanji)
        }
        
        return result
    }
    
    private static func convertKanjiToNumerals(_ text: String) -> String {
        var result = text
        
        // Replace individual kanji digits with Arabic numerals
        for (kanji, arabic) in kanjiToArabic {
            result = result.replacingOccurrences(of: kanji, with: arabic)
        }
        
        return result
    }
    
    // MARK: - Advanced Conversion (Future Enhancement)
    
    // This could be extended to handle more complex number formats like:
    // - 十二 (12) ↔ 12
    // - 百二十三 (123) ↔ 123
    // - 二千二十四 (2024) ↔ 2024
    // For now, we'll use the simpler digit-by-digit conversion
    
    private static func convertComplexKanjiNumber(_ kanjiText: String) -> String {
        // TODO: Future enhancement for complex number patterns
        // This would handle cases like 十二 -> 12, 百二十三 -> 123, etc.
        return kanjiText
    }
    
    private static func convertComplexArabicNumber(_ arabicText: String) -> String {
        // TODO: Future enhancement for complex number patterns
        // This would handle cases like 12 -> 十二, 123 -> 百二十三, etc.
        return arabicText
    }
}