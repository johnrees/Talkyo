//
//  PitchAccentService.swift
//  Talkyo
//
//  Service for looking up Japanese pitch accent patterns
//

import Foundation

// MARK: - Pitch Accent Service

/// Service responsible for looking up pitch accent patterns for Japanese words
enum PitchAccentService {
    
    // MARK: - Public Methods
    
    /// Look up pitch accent pattern for a given Japanese word/reading
    /// - Parameters:
    ///   - text: The original text (may contain kanji)
    ///   - reading: The hiragana reading of the text
    /// - Returns: PitchAccentPattern if found, nil otherwise
    static func lookupPitchPattern(for text: String, reading: String?) -> PitchAccentPattern? {
        // Use the reading if available, otherwise fall back to original text
        let lookupKey = reading ?? text
        
        // Look up in our embedded database
        return pitchAccentDatabase[lookupKey]
    }
    
    /// Get pitch pattern for a specific reading string
    /// - Parameter reading: The hiragana reading to look up
    /// - Returns: PitchAccentPattern if found, nil otherwise
    static func lookupPitchPattern(forReading reading: String) -> PitchAccentPattern? {
        return pitchAccentDatabase[reading]
    }
    
    // MARK: - Sample Database
    
    /// Embedded pitch accent database with common Japanese words
    /// Key: hiragana reading, Value: pitch accent pattern
    private static let pitchAccentDatabase: [String: PitchAccentPattern] = [
        // Greetings and common phrases
        "おはよう": PitchAccentPattern(pitches: [0, 1, 1, 1], accentPosition: 0, confidence: 0.95),
        "おはようございます": PitchAccentPattern(pitches: [0, 1, 1, 1, 0, 0, 0, 0], accentPosition: 4, confidence: 0.95),
        "こんにちは": PitchAccentPattern(pitches: [0, 1, 1, 1, 0], accentPosition: 4, confidence: 0.95),
        "こんばんは": PitchAccentPattern(pitches: [0, 1, 1, 1, 0], accentPosition: 4, confidence: 0.95),
        "ありがとう": PitchAccentPattern(pitches: [0, 1, 1, 0, 0], accentPosition: 3, confidence: 0.95),
        "ありがとうございます": PitchAccentPattern(pitches: [0, 1, 1, 0, 0, 0, 0, 0], accentPosition: 3, confidence: 0.95),
        "すみません": PitchAccentPattern(pitches: [0, 1, 1, 0], accentPosition: 3, confidence: 0.95),
        "よろしく": PitchAccentPattern(pitches: [0, 1, 1, 0], accentPosition: 3, confidence: 0.95),
        "よろしくお願いします": PitchAccentPattern(pitches: [0, 1, 1, 0, 0, 1, 1, 0, 0], accentPosition: 3, confidence: 0.95),
        "おねがいします": PitchAccentPattern(pitches: [0, 1, 1, 0, 0, 0], accentPosition: 3, confidence: 0.95),
        
        // Basic words
        "はい": PitchAccentPattern(pitches: [1, 0], accentPosition: 1, confidence: 0.95),
        "いいえ": PitchAccentPattern(pitches: [1, 1, 0], accentPosition: 2, confidence: 0.95),
        "です": PitchAccentPattern(pitches: [0, 0], accentPosition: 0, confidence: 0.95),
        "だ": PitchAccentPattern(pitches: [1], accentPosition: 0, confidence: 0.95),
        "である": PitchAccentPattern(pitches: [0, 1, 1], accentPosition: 0, confidence: 0.90),
        
        // Numbers
        "いち": PitchAccentPattern(pitches: [1, 0], accentPosition: 1, confidence: 0.95),
        "に": PitchAccentPattern(pitches: [1], accentPosition: 0, confidence: 0.95),
        "さん": PitchAccentPattern(pitches: [1], accentPosition: 0, confidence: 0.95),
        "よん": PitchAccentPattern(pitches: [1], accentPosition: 0, confidence: 0.95),
        "ご": PitchAccentPattern(pitches: [1], accentPosition: 0, confidence: 0.95),
        "ろく": PitchAccentPattern(pitches: [1], accentPosition: 0, confidence: 0.95),
        "なな": PitchAccentPattern(pitches: [1, 0], accentPosition: 1, confidence: 0.95),
        "はち": PitchAccentPattern(pitches: [1, 0], accentPosition: 1, confidence: 0.95),
        "きゅう": PitchAccentPattern(pitches: [1, 0], accentPosition: 1, confidence: 0.95),
        "じゅう": PitchAccentPattern(pitches: [1, 0], accentPosition: 1, confidence: 0.95),
        
        // Common verbs
        "する": PitchAccentPattern(pitches: [0, 1], accentPosition: 0, confidence: 0.95),
        "いく": PitchAccentPattern(pitches: [1, 0], accentPosition: 1, confidence: 0.95),
        "くる": PitchAccentPattern(pitches: [0, 1], accentPosition: 0, confidence: 0.95),
        "みる": PitchAccentPattern(pitches: [1, 0], accentPosition: 1, confidence: 0.95),
        "きく": PitchAccentPattern(pitches: [0, 1], accentPosition: 0, confidence: 0.95),
        "はなす": PitchAccentPattern(pitches: [0, 1, 0], accentPosition: 2, confidence: 0.95),
        "たべる": PitchAccentPattern(pitches: [0, 1, 0], accentPosition: 2, confidence: 0.95),
        "のむ": PitchAccentPattern(pitches: [0, 1], accentPosition: 0, confidence: 0.95),
        
        // Common nouns
        "ひと": PitchAccentPattern(pitches: [0, 1], accentPosition: 0, confidence: 0.95),
        "みず": PitchAccentPattern(pitches: [0, 1], accentPosition: 0, confidence: 0.95),
        "あめ": PitchAccentPattern(pitches: [1, 0], accentPosition: 1, confidence: 0.95), // rain
        "やま": PitchAccentPattern(pitches: [0, 1], accentPosition: 0, confidence: 0.95),
        "うみ": PitchAccentPattern(pitches: [1, 0], accentPosition: 1, confidence: 0.95),
        "そら": PitchAccentPattern(pitches: [0, 1], accentPosition: 0, confidence: 0.95),
        "つき": PitchAccentPattern(pitches: [0, 1], accentPosition: 0, confidence: 0.95),
        "ほし": PitchAccentPattern(pitches: [0, 1], accentPosition: 0, confidence: 0.95),
        "にち": PitchAccentPattern(pitches: [0, 1], accentPosition: 0, confidence: 0.95),
        
        // Time expressions
        "いま": PitchAccentPattern(pitches: [0, 1], accentPosition: 0, confidence: 0.95),
        "あした": PitchAccentPattern(pitches: [0, 1, 0], accentPosition: 2, confidence: 0.95),
        "きょう": PitchAccentPattern(pitches: [0, 1], accentPosition: 0, confidence: 0.95),
        "きのう": PitchAccentPattern(pitches: [0, 1, 0], accentPosition: 2, confidence: 0.95),
        
        // Adjectives
        "おおきい": PitchAccentPattern(pitches: [0, 1, 1, 0], accentPosition: 3, confidence: 0.95),
        "ちいさい": PitchAccentPattern(pitches: [0, 1, 1, 0], accentPosition: 3, confidence: 0.95),
        "あたらしい": PitchAccentPattern(pitches: [0, 1, 1, 1, 0], accentPosition: 4, confidence: 0.95),
        "ふるい": PitchAccentPattern(pitches: [0, 1, 0], accentPosition: 2, confidence: 0.95),
        "いい": PitchAccentPattern(pitches: [1, 0], accentPosition: 1, confidence: 0.95),
        "わるい": PitchAccentPattern(pitches: [0, 1, 0], accentPosition: 2, confidence: 0.95),
        
        // Family
        "おかあさん": PitchAccentPattern(pitches: [0, 1, 1, 0], accentPosition: 3, confidence: 0.95),
        "おとうさん": PitchAccentPattern(pitches: [0, 1, 1, 0], accentPosition: 3, confidence: 0.95),
        "おにいさん": PitchAccentPattern(pitches: [0, 1, 1, 0], accentPosition: 3, confidence: 0.95),
        "おねえさん": PitchAccentPattern(pitches: [0, 1, 1, 0], accentPosition: 3, confidence: 0.95),
        
        // Common sentence endings and particles
        "です": PitchAccentPattern(pitches: [0, 0], accentPosition: 0, confidence: 0.95),
        "ます": PitchAccentPattern(pitches: [0, 0], accentPosition: 0, confidence: 0.95),
        "でした": PitchAccentPattern(pitches: [0, 0, 0], accentPosition: 0, confidence: 0.95),
        "ました": PitchAccentPattern(pitches: [0, 0, 0], accentPosition: 0, confidence: 0.95),
    ]
    
    // MARK: - Database Management
    
    /// Get the total number of entries in the pitch accent database
    static var databaseSize: Int {
        return pitchAccentDatabase.count
    }
    
    /// Check if a reading exists in the database
    static func hasEntry(for reading: String) -> Bool {
        return pitchAccentDatabase[reading] != nil
    }
    
    /// Get all available readings in the database (for debugging/testing)
    static var allReadings: [String] {
        return Array(pitchAccentDatabase.keys).sorted()
    }
}