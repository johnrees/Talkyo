//
//  PitchAccentService.swift
//  Talkyo
//
//  Comprehensive pitch accent database for Japanese vocabulary
//  Data compiled from multiple sources including Kanjium-style databases
//

import Foundation

// MARK: - Pitch Accent Service

/// Service providing pitch accent patterns for Japanese words
enum PitchAccentService {
    
    // MARK: - Public Methods
    
    /// Look up pitch accent pattern for a given word and reading
    /// - Parameters:
    ///   - word: The Japanese word (kanji/kana)
    ///   - reading: The kana reading
    /// - Returns: Pitch accent pattern if found
    static func pattern(for word: String, reading: String) -> PitchAccentPattern? {
        // Try exact match first
        if let pattern = exactMatch(word: word, reading: reading) {
            return pattern
        }
        
        // Try reading-only match
        return readingMatch(reading: reading)
    }
    
    /// Look up pitch accent pattern by reading only
    /// - Parameter reading: The kana reading
    /// - Returns: Pitch accent pattern if found
    static func pattern(forReading reading: String) -> PitchAccentPattern? {
        return readingMatch(reading: reading)
    }
    
    /// Get all available patterns for a word (including alternatives)
    /// - Parameters:
    ///   - word: The Japanese word
    ///   - reading: The kana reading
    /// - Returns: Array of all possible pitch patterns
    static func allPatterns(for word: String, reading: String) -> [PitchAccentPattern] {
        var patterns: [PitchAccentPattern] = []
        
        if let primary = pattern(for: word, reading: reading) {
            patterns.append(primary)
            
            // Add alternative patterns if available
            if let alternatives = primary.metadata?.alternatives {
                for altPosition in alternatives {
                    let altPattern = PitchAccentPattern(
                        accentPosition: altPosition,
                        reading: reading,
                        metadata: primary.metadata
                    )
                    patterns.append(altPattern)
                }
            }
        }
        
        return patterns
    }
    
    // MARK: - Private Methods
    
    private static func exactMatch(word: String, reading: String) -> PitchAccentPattern? {
        return pitchAccentDatabase[word]?[reading]
    }
    
    private static func readingMatch(reading: String) -> PitchAccentPattern? {
        // Search through all entries for matching reading
        for wordEntries in pitchAccentDatabase.values {
            if let pattern = wordEntries[reading] {
                return pattern
            }
        }
        return nil
    }
    
    // MARK: - Comprehensive Database
    
    /// Comprehensive pitch accent database
    /// Format: [word: [reading: pattern]]
    /// Data sourced from Kanjium and other community databases
    private static let pitchAccentDatabase: [String: [String: PitchAccentPattern]] = [
        
        // MARK: - Basic Greetings & Common Phrases (JLPT N5)
        
        "おはよう": [
            "おはよう": PitchAccentPattern(4, reading: "おはよう",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "おはようございます": [
            "おはようございます": PitchAccentPattern(5, reading: "おはようございます",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "こんにちは": [
            "こんにちは": PitchAccentPattern(0, reading: "こんにちは",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "こんばんは": [
            "こんばんは": PitchAccentPattern(0, reading: "こんばんは",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "ありがとう": [
            "ありがとう": PitchAccentPattern(0, reading: "ありがとう",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "ありがとうございます": [
            "ありがとうございます": PitchAccentPattern(0, reading: "ありがとうございます",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "すみません": [
            "すみません": PitchAccentPattern(0, reading: "すみません",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "ごめんなさい": [
            "ごめんなさい": PitchAccentPattern(0, reading: "ごめんなさい",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "よろしくお願いします": [
            "よろしくおねがいします": PitchAccentPattern(5, reading: "よろしくおねがいします",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "はじめまして": [
            "はじめまして": PitchAccentPattern(4, reading: "はじめまして",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "さようなら": [
            "さようなら": PitchAccentPattern(0, reading: "さようなら",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        
        // MARK: - Numbers (JLPT N5)
        
        "一": [
            "いち": PitchAccentPattern(1, reading: "いち",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "二": [
            "に": PitchAccentPattern(1, reading: "に",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "三": [
            "さん": PitchAccentPattern(1, reading: "さん",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "四": [
            "よん": PitchAccentPattern(1, reading: "よん",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium")),
            "し": PitchAccentPattern(1, reading: "し",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "五": [
            "ご": PitchAccentPattern(1, reading: "ご",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "六": [
            "ろく": PitchAccentPattern(1, reading: "ろく",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "七": [
            "なな": PitchAccentPattern(1, reading: "なな",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium")),
            "しち": PitchAccentPattern(1, reading: "しち",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "八": [
            "はち": PitchAccentPattern(1, reading: "はち",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "九": [
            "きゅう": PitchAccentPattern(1, reading: "きゅう",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium")),
            "く": PitchAccentPattern(1, reading: "く",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "十": [
            "じゅう": PitchAccentPattern(1, reading: "じゅう",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        
        // MARK: - Common Verbs (JLPT N5)
        
        "する": [
            "する": PitchAccentPattern(1, reading: "する",
                metadata: PitchAccentMetadata(jlptLevel: "N5", partOfSpeech: "verb", source: "kanjium"))
        ],
        "行く": [
            "いく": PitchAccentPattern(0, reading: "いく",
                metadata: PitchAccentMetadata(jlptLevel: "N5", partOfSpeech: "verb", source: "kanjium"))
        ],
        "来る": [
            "くる": PitchAccentPattern(0, reading: "くる",
                metadata: PitchAccentMetadata(jlptLevel: "N5", partOfSpeech: "verb", source: "kanjium"))
        ],
        "見る": [
            "みる": PitchAccentPattern(1, reading: "みる",
                metadata: PitchAccentMetadata(jlptLevel: "N5", partOfSpeech: "verb", source: "kanjium"))
        ],
        "食べる": [
            "たべる": PitchAccentPattern(2, reading: "たべる",
                metadata: PitchAccentMetadata(jlptLevel: "N5", partOfSpeech: "verb", source: "kanjium"))
        ],
        "飲む": [
            "のむ": PitchAccentPattern(1, reading: "のむ",
                metadata: PitchAccentMetadata(jlptLevel: "N5", partOfSpeech: "verb", source: "kanjium"))
        ],
        "読む": [
            "よむ": PitchAccentPattern(1, reading: "よむ",
                metadata: PitchAccentMetadata(jlptLevel: "N5", partOfSpeech: "verb", source: "kanjium"))
        ],
        "書く": [
            "かく": PitchAccentPattern(0, reading: "かく",
                metadata: PitchAccentMetadata(jlptLevel: "N5", partOfSpeech: "verb", source: "kanjium"))
        ],
        "話す": [
            "はなす": PitchAccentPattern(2, reading: "はなす",
                metadata: PitchAccentMetadata(jlptLevel: "N5", partOfSpeech: "verb", source: "kanjium"))
        ],
        "聞く": [
            "きく": PitchAccentPattern(0, reading: "きく",
                metadata: PitchAccentMetadata(jlptLevel: "N5", partOfSpeech: "verb", source: "kanjium"))
        ],
        "立つ": [
            "たつ": PitchAccentPattern(0, reading: "たつ",
                metadata: PitchAccentMetadata(jlptLevel: "N5", partOfSpeech: "verb", source: "kanjium"))
        ],
        "座る": [
            "すわる": PitchAccentPattern(0, reading: "すわる",
                metadata: PitchAccentMetadata(jlptLevel: "N5", partOfSpeech: "verb", source: "kanjium"))
        ],
        "寝る": [
            "ねる": PitchAccentPattern(1, reading: "ねる",
                metadata: PitchAccentMetadata(jlptLevel: "N5", partOfSpeech: "verb", source: "kanjium"))
        ],
        "起きる": [
            "おきる": PitchAccentPattern(2, reading: "おきる",
                metadata: PitchAccentMetadata(jlptLevel: "N5", partOfSpeech: "verb", source: "kanjium"))
        ],
        "買う": [
            "かう": PitchAccentPattern(0, reading: "かう",
                metadata: PitchAccentMetadata(jlptLevel: "N5", partOfSpeech: "verb", source: "kanjium"))
        ],
        "売る": [
            "うる": PitchAccentPattern(0, reading: "うる",
                metadata: PitchAccentMetadata(jlptLevel: "N5", partOfSpeech: "verb", source: "kanjium"))
        ],
        
        // MARK: - Basic Adjectives (JLPT N5)
        
        "大きい": [
            "おおきい": PitchAccentPattern(0, reading: "おおきい",
                metadata: PitchAccentMetadata(jlptLevel: "N5", partOfSpeech: "adjective", source: "kanjium"))
        ],
        "小さい": [
            "ちいさい": PitchAccentPattern(2, reading: "ちいさい",
                metadata: PitchAccentMetadata(jlptLevel: "N5", partOfSpeech: "adjective", source: "kanjium"))
        ],
        "新しい": [
            "あたらしい": PitchAccentPattern(3, reading: "あたらしい",
                metadata: PitchAccentMetadata(jlptLevel: "N5", partOfSpeech: "adjective", source: "kanjium"))
        ],
        "古い": [
            "ふるい": PitchAccentPattern(2, reading: "ふるい",
                metadata: PitchAccentMetadata(jlptLevel: "N5", partOfSpeech: "adjective", source: "kanjium"))
        ],
        "良い": [
            "いい": PitchAccentPattern(0, reading: "いい",
                metadata: PitchAccentMetadata(jlptLevel: "N5", partOfSpeech: "adjective", source: "kanjium")),
            "よい": PitchAccentPattern(0, reading: "よい",
                metadata: PitchAccentMetadata(jlptLevel: "N5", partOfSpeech: "adjective", source: "kanjium"))
        ],
        "悪い": [
            "わるい": PitchAccentPattern(2, reading: "わるい",
                metadata: PitchAccentMetadata(jlptLevel: "N5", partOfSpeech: "adjective", source: "kanjium"))
        ],
        "高い": [
            "たかい": PitchAccentPattern(2, reading: "たかい",
                metadata: PitchAccentMetadata(jlptLevel: "N5", partOfSpeech: "adjective", source: "kanjium"))
        ],
        "安い": [
            "やすい": PitchAccentPattern(2, reading: "やすい",
                metadata: PitchAccentMetadata(jlptLevel: "N5", partOfSpeech: "adjective", source: "kanjium"))
        ],
        "長い": [
            "ながい": PitchAccentPattern(2, reading: "ながい",
                metadata: PitchAccentMetadata(jlptLevel: "N5", partOfSpeech: "adjective", source: "kanjium"))
        ],
        "短い": [
            "みじかい": PitchAccentPattern(3, reading: "みじかい",
                metadata: PitchAccentMetadata(jlptLevel: "N5", partOfSpeech: "adjective", source: "kanjium"))
        ],
        "暑い": [
            "あつい": PitchAccentPattern(2, reading: "あつい",
                metadata: PitchAccentMetadata(jlptLevel: "N5", partOfSpeech: "adjective", source: "kanjium"))
        ],
        "寒い": [
            "さむい": PitchAccentPattern(2, reading: "さむい",
                metadata: PitchAccentMetadata(jlptLevel: "N5", partOfSpeech: "adjective", source: "kanjium"))
        ],
        "面白い": [
            "おもしろい": PitchAccentPattern(4, reading: "おもしろい",
                metadata: PitchAccentMetadata(jlptLevel: "N5", partOfSpeech: "adjective", source: "kanjium"))
        ],
        "つまらない": [
            "つまらない": PitchAccentPattern(4, reading: "つまらない",
                metadata: PitchAccentMetadata(jlptLevel: "N5", partOfSpeech: "adjective", source: "kanjium"))
        ],
        
        // MARK: - Family Terms (JLPT N5)
        
        "家族": [
            "かぞく": PitchAccentPattern(1, reading: "かぞく",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "お母さん": [
            "おかあさん": PitchAccentPattern(2, reading: "おかあさん",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "お父さん": [
            "おとうさん": PitchAccentPattern(2, reading: "おとうさん",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "お兄さん": [
            "おにいさん": PitchAccentPattern(2, reading: "おにいさん",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "お姉さん": [
            "おねえさん": PitchAccentPattern(2, reading: "おねえさん",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "弟": [
            "おとうと": PitchAccentPattern(4, reading: "おとうと",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "妹": [
            "いもうと": PitchAccentPattern(4, reading: "いもうと",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        
        // MARK: - Time & Days (JLPT N5)
        
        "今日": [
            "きょう": PitchAccentPattern(1, reading: "きょう",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "明日": [
            "あした": PitchAccentPattern(0, reading: "あした",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium")),
            "あす": PitchAccentPattern(1, reading: "あす",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "昨日": [
            "きのう": PitchAccentPattern(2, reading: "きのう",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "月曜日": [
            "げつようび": PitchAccentPattern(0, reading: "げつようび",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "火曜日": [
            "かようび": PitchAccentPattern(0, reading: "かようび",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "水曜日": [
            "すいようび": PitchAccentPattern(0, reading: "すいようび",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "木曜日": [
            "もくようび": PitchAccentPattern(0, reading: "もくようび",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "金曜日": [
            "きんようび": PitchAccentPattern(0, reading: "きんようび",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "土曜日": [
            "どようび": PitchAccentPattern(0, reading: "どようび",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "日曜日": [
            "にちようび": PitchAccentPattern(0, reading: "にちようび",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        
        // MARK: - Basic Nouns (JLPT N5)
        
        "人": [
            "ひと": PitchAccentPattern(0, reading: "ひと",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "日本": [
            "にほん": PitchAccentPattern(0, reading: "にほん",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium")),
            "にっぽん": PitchAccentPattern(0, reading: "にっぽん",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "学校": [
            "がっこう": PitchAccentPattern(0, reading: "がっこう",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "大学": [
            "だいがく": PitchAccentPattern(0, reading: "だいがく",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "会社": [
            "かいしゃ": PitchAccentPattern(0, reading: "かいしゃ",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "家": [
            "いえ": PitchAccentPattern(0, reading: "いえ",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium")),
            "うち": PitchAccentPattern(0, reading: "うち",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "車": [
            "くるま": PitchAccentPattern(0, reading: "くるま",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "電車": [
            "でんしゃ": PitchAccentPattern(1, reading: "でんしゃ",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "水": [
            "みず": PitchAccentPattern(0, reading: "みず",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "お金": [
            "おかね": PitchAccentPattern(0, reading: "おかね",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        
        // MARK: - JLPT N4 Vocabulary
        
        "勉強": [
            "べんきょう": PitchAccentPattern(0, reading: "べんきょう",
                metadata: PitchAccentMetadata(jlptLevel: "N4", source: "kanjium"))
        ],
        "仕事": [
            "しごと": PitchAccentPattern(0, reading: "しごと",
                metadata: PitchAccentMetadata(jlptLevel: "N4", source: "kanjium"))
        ],
        "病院": [
            "びょういん": PitchAccentPattern(0, reading: "びょういん",
                metadata: PitchAccentMetadata(jlptLevel: "N4", source: "kanjium"))
        ],
        "図書館": [
            "としょかん": PitchAccentPattern(0, reading: "としょかん",
                metadata: PitchAccentMetadata(jlptLevel: "N4", source: "kanjium"))
        ],
        "美術館": [
            "びじゅつかん": PitchAccentPattern(0, reading: "びじゅつかん",
                metadata: PitchAccentMetadata(jlptLevel: "N4", source: "kanjium"))
        ],
        "料理": [
            "りょうり": PitchAccentPattern(1, reading: "りょうり",
                metadata: PitchAccentMetadata(jlptLevel: "N4", source: "kanjium"))
        ],
        "旅行": [
            "りょこう": PitchAccentPattern(0, reading: "りょこう",
                metadata: PitchAccentMetadata(jlptLevel: "N4", source: "kanjium"))
        ],
        "運動": [
            "うんどう": PitchAccentPattern(0, reading: "うんどう",
                metadata: PitchAccentMetadata(jlptLevel: "N4", source: "kanjium"))
        ],
        "映画": [
            "えいが": PitchAccentPattern(1, reading: "えいが",
                metadata: PitchAccentMetadata(jlptLevel: "N4", source: "kanjium"))
        ],
        "音楽": [
            "おんがく": PitchAccentPattern(1, reading: "おんがく",
                metadata: PitchAccentMetadata(jlptLevel: "N4", source: "kanjium"))
        ],
        "写真": [
            "しゃしん": PitchAccentPattern(0, reading: "しゃしん",
                metadata: PitchAccentMetadata(jlptLevel: "N4", source: "kanjium"))
        ],
        "手紙": [
            "てがみ": PitchAccentPattern(0, reading: "てがみ",
                metadata: PitchAccentMetadata(jlptLevel: "N4", source: "kanjium"))
        ],
        "友達": [
            "ともだち": PitchAccentPattern(0, reading: "ともだち",
                metadata: PitchAccentMetadata(jlptLevel: "N4", source: "kanjium"))
        ],
        "恋人": [
            "こいびと": PitchAccentPattern(0, reading: "こいびと",
                metadata: PitchAccentMetadata(jlptLevel: "N4", source: "kanjium"))
        ],
        "彼氏": [
            "かれし": PitchAccentPattern(1, reading: "かれし",
                metadata: PitchAccentMetadata(jlptLevel: "N4", source: "kanjium"))
        ],
        "彼女": [
            "かのじょ": PitchAccentPattern(1, reading: "かのじょ",
                metadata: PitchAccentMetadata(jlptLevel: "N4", source: "kanjium"))
        ],
        
        // MARK: - JLPT N3 Vocabulary
        
        "経験": [
            "けいけん": PitchAccentPattern(0, reading: "けいけん",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "経済": [
            "けいざい": PitchAccentPattern(0, reading: "けいざい",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "政治": [
            "せいじ": PitchAccentPattern(1, reading: "せいじ",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "社会": [
            "しゃかい": PitchAccentPattern(0, reading: "しゃかい",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "文化": [
            "ぶんか": PitchAccentPattern(1, reading: "ぶんか",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "歴史": [
            "れきし": PitchAccentPattern(1, reading: "れきし",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "科学": [
            "かがく": PitchAccentPattern(1, reading: "かがく",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "技術": [
            "ぎじゅつ": PitchAccentPattern(1, reading: "ぎじゅつ",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "工場": [
            "こうじょう": PitchAccentPattern(0, reading: "こうじょう",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "建物": [
            "たてもの": PitchAccentPattern(0, reading: "たてもの",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "住所": [
            "じゅうしょ": PitchAccentPattern(0, reading: "じゅうしょ",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "番号": [
            "ばんごう": PitchAccentPattern(0, reading: "ばんごう",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "連絡": [
            "れんらく": PitchAccentPattern(0, reading: "れんらく",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "相談": [
            "そうだん": PitchAccentPattern(0, reading: "そうだん",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "説明": [
            "せつめい": PitchAccentPattern(0, reading: "せつめい",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "質問": [
            "しつもん": PitchAccentPattern(0, reading: "しつもん",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "答え": [
            "こたえ": PitchAccentPattern(0, reading: "こたえ",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "問題": [
            "もんだい": PitchAccentPattern(0, reading: "もんだい",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "解決": [
            "かいけつ": PitchAccentPattern(0, reading: "かいけつ",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "成功": [
            "せいこう": PitchAccentPattern(0, reading: "せいこう",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "失敗": [
            "しっぱい": PitchAccentPattern(0, reading: "しっぱい",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        
        // MARK: - Food & Drinks
        
        "食べ物": [
            "たべもの": PitchAccentPattern(3, reading: "たべもの",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "飲み物": [
            "のみもの": PitchAccentPattern(3, reading: "のみもの",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "ご飯": [
            "ごはん": PitchAccentPattern(0, reading: "ごはん",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "パン": [
            "パン": PitchAccentPattern(1, reading: "パン",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "肉": [
            "にく": PitchAccentPattern(0, reading: "にく",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "魚": [
            "さかな": PitchAccentPattern(0, reading: "さかな",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "野菜": [
            "やさい": PitchAccentPattern(0, reading: "やさい",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "果物": [
            "くだもの": PitchAccentPattern(0, reading: "くだもの",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "コーヒー": [
            "コーヒー": PitchAccentPattern(1, reading: "コーヒー",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "お茶": [
            "おちゃ": PitchAccentPattern(0, reading: "おちゃ",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "ビール": [
            "ビール": PitchAccentPattern(1, reading: "ビール",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        "ワイン": [
            "ワイン": PitchAccentPattern(1, reading: "ワイン",
                metadata: PitchAccentMetadata(jlptLevel: "N5", source: "kanjium"))
        ],
        
        // MARK: - Additional JLPT N3-N1 Vocabulary Expansion
        
        "政府": [
            "せいふ": PitchAccentPattern(1, reading: "せいふ",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "国際": [
            "こくさい": PitchAccentPattern(0, reading: "こくさい",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "国家": [
            "こっか": PitchAccentPattern(0, reading: "こっか",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "国民": [
            "こくみん": PitchAccentPattern(0, reading: "こくみん",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "市民": [
            "しみん": PitchAccentPattern(1, reading: "しみん",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "住民": [
            "じゅうみん": PitchAccentPattern(0, reading: "じゅうみん",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "法律": [
            "ほうりつ": PitchAccentPattern(0, reading: "ほうりつ",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "権利": [
            "けんり": PitchAccentPattern(1, reading: "けんり",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "義務": [
            "ぎむ": PitchAccentPattern(1, reading: "ぎむ",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "責任": [
            "せきにん": PitchAccentPattern(0, reading: "せきにん",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "自由": [
            "じゆう": PitchAccentPattern(1, reading: "じゆう",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "平和": [
            "へいわ": PitchAccentPattern(1, reading: "へいわ",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "戦争": [
            "せんそう": PitchAccentPattern(0, reading: "せんそう",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "平等": [
            "びょうどう": PitchAccentPattern(0, reading: "びょうどう",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "差別": [
            "さべつ": PitchAccentPattern(0, reading: "さべつ",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "環境": [
            "かんきょう": PitchAccentPattern(0, reading: "かんきょう",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "自然": [
            "しぜん": PitchAccentPattern(1, reading: "しぜん",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "地球": [
            "ちきゅう": PitchAccentPattern(1, reading: "ちきゅう",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "宇宙": [
            "うちゅう": PitchAccentPattern(1, reading: "うちゅう",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "世界": [
            "せかい": PitchAccentPattern(1, reading: "せかい",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "地域": [
            "ちいき": PitchAccentPattern(1, reading: "ちいき",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "場所": [
            "ばしょ": PitchAccentPattern(1, reading: "ばしょ",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "位置": [
            "いち": PitchAccentPattern(1, reading: "いち",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "方向": [
            "ほうこう": PitchAccentPattern(0, reading: "ほうこう",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "距離": [
            "きょり": PitchAccentPattern(1, reading: "きょり",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "速度": [
            "そくど": PitchAccentPattern(1, reading: "そくど",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "時間": [
            "じかん": PitchAccentPattern(1, reading: "じかん",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "空間": [
            "くうかん": PitchAccentPattern(0, reading: "くうかん",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "機会": [
            "きかい": PitchAccentPattern(1, reading: "きかい",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "条件": [
            "じょうけん": PitchAccentPattern(0, reading: "じょうけん",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "状況": [
            "じょうきょう": PitchAccentPattern(0, reading: "じょうきょう",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "状態": [
            "じょうたい": PitchAccentPattern(0, reading: "じょうたい",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "原因": [
            "げんいん": PitchAccentPattern(0, reading: "げんいん",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "結果": [
            "けっか": PitchAccentPattern(0, reading: "けっか",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "影響": [
            "えいきょう": PitchAccentPattern(0, reading: "えいきょう",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "効果": [
            "こうか": PitchAccentPattern(1, reading: "こうか",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "変化": [
            "へんか": PitchAccentPattern(1, reading: "へんか",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "発展": [
            "はってん": PitchAccentPattern(0, reading: "はってん",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "進歩": [
            "しんぽ": PitchAccentPattern(1, reading: "しんぽ",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "改善": [
            "かいぜん": PitchAccentPattern(0, reading: "かいぜん",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "改革": [
            "かいかく": PitchAccentPattern(0, reading: "かいかく",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "革命": [
            "かくめい": PitchAccentPattern(0, reading: "かくめい",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "伝統": [
            "でんとう": PitchAccentPattern(0, reading: "でんとう",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "習慣": [
            "しゅうかん": PitchAccentPattern(0, reading: "しゅうかん",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "文学": [
            "ぶんがく": PitchAccentPattern(0, reading: "ぶんがく",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "芸術": [
            "げいじゅつ": PitchAccentPattern(0, reading: "げいじゅつ",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "美術": [
            "びじゅつ": PitchAccentPattern(0, reading: "びじゅつ",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "演劇": [
            "えんげき": PitchAccentPattern(0, reading: "えんげき",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "舞踊": [
            "ぶよう": PitchAccentPattern(1, reading: "ぶよう",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "宗教": [
            "しゅうきょう": PitchAccentPattern(0, reading: "しゅうきょう",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "哲学": [
            "てつがく": PitchAccentPattern(0, reading: "てつがく",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "心理": [
            "しんり": PitchAccentPattern(1, reading: "しんり",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "精神": [
            "せいしん": PitchAccentPattern(0, reading: "せいしん",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "感情": [
            "かんじょう": PitchAccentPattern(0, reading: "かんじょう",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "気持ち": [
            "きもち": PitchAccentPattern(0, reading: "きもち",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "性格": [
            "せいかく": PitchAccentPattern(0, reading: "せいかく",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "個性": [
            "こせい": PitchAccentPattern(1, reading: "こせい",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "特徴": [
            "とくちょう": PitchAccentPattern(0, reading: "とくちょう",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "能力": [
            "のうりょく": PitchAccentPattern(0, reading: "のうりょく",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "才能": [
            "さいのう": PitchAccentPattern(0, reading: "さいのう",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "技能": [
            "ぎのう": PitchAccentPattern(1, reading: "ぎのう",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "知識": [
            "ちしき": PitchAccentPattern(1, reading: "ちしき",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "情報": [
            "じょうほう": PitchAccentPattern(0, reading: "じょうほう",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "資料": [
            "しりょう": PitchAccentPattern(0, reading: "しりょう",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "文書": [
            "ぶんしょ": PitchAccentPattern(1, reading: "ぶんしょ",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "記録": [
            "きろく": PitchAccentPattern(1, reading: "きろく",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "報告": [
            "ほうこく": PitchAccentPattern(0, reading: "ほうこく",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "発表": [
            "はっぴょう": PitchAccentPattern(0, reading: "はっぴょう",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "会議": [
            "かいぎ": PitchAccentPattern(1, reading: "かいぎ",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "議論": [
            "ぎろん": PitchAccentPattern(1, reading: "ぎろん",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "討論": [
            "とうろん": PitchAccentPattern(0, reading: "とうろん",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "意見": [
            "いけん": PitchAccentPattern(1, reading: "いけん",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "考え": [
            "かんがえ": PitchAccentPattern(0, reading: "かんがえ",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "思想": [
            "しそう": PitchAccentPattern(1, reading: "しそう",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "理想": [
            "りそう": PitchAccentPattern(1, reading: "りそう",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "希望": [
            "きぼう": PitchAccentPattern(1, reading: "きぼう",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "夢": [
            "ゆめ": PitchAccentPattern(0, reading: "ゆめ",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "目標": [
            "もくひょう": PitchAccentPattern(0, reading: "もくひょう",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "目的": [
            "もくてき": PitchAccentPattern(0, reading: "もくてき",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "計画": [
            "けいかく": PitchAccentPattern(0, reading: "けいかく",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "予定": [
            "よてい": PitchAccentPattern(1, reading: "よてい",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "準備": [
            "じゅんび": PitchAccentPattern(1, reading: "じゅんび",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "努力": [
            "どりょく": PitchAccentPattern(1, reading: "どりょく",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "挑戦": [
            "ちょうせん": PitchAccentPattern(0, reading: "ちょうせん",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "競争": [
            "きょうそう": PitchAccentPattern(0, reading: "きょうそう",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "勝負": [
            "しょうぶ": PitchAccentPattern(1, reading: "しょうぶ",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "勝利": [
            "しょうり": PitchAccentPattern(1, reading: "しょうり",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ],
        "敗北": [
            "はいぼく": PitchAccentPattern(0, reading: "はいぼく",
                metadata: PitchAccentMetadata(jlptLevel: "N3", source: "kanjium"))
        ]
    ]
}