import Foundation

enum FuriganaGenerator {
  static func generate(for text: String) -> String {
    guard textRequiresFurigana(text) else {
      return ""
    }

    let furiganaText = generateFuriganaText(from: text)
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

      if lastEndIndex < startIndex {
        let skippedText = String(text[lastEndIndex..<startIndex])
        tokens.append(FuriganaToken(text: skippedText, reading: nil))
      }

      let tokenText = String(text[startIndex..<endIndex])
      let reading = extractHiraganaReading(from: tokenizer)

      let splitTokens = splitMixedToken(text: tokenText, reading: reading)
      tokens.append(contentsOf: splitTokens)

      lastEndIndex = endIndex
      tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)
    }

    if lastEndIndex < text.endIndex {
      let remainingText = String(text[lastEndIndex..<text.endIndex])
      tokens.append(FuriganaToken(text: remainingText, reading: nil))
    }

    return tokens
  }
  private static func splitMixedToken(text: String, reading: String?) -> [FuriganaToken] {
    guard let reading = reading, !text.isEmpty else {
      return [FuriganaToken(text: text, reading: nil)]
    }

    if text.allSatisfy({ isHiragana($0) || isKatakana($0) }) {
      return [FuriganaToken(text: text, reading: nil)]
    }

    if text.allSatisfy({ isKanji($0) }) {
      return [FuriganaToken(text: text, reading: reading)]
    }

    return splitMixedTokenByCharacterType(text: text, reading: reading)
  }
  private static func splitMixedTokenByCharacterType(text: String, reading: String) -> [FuriganaToken] {
    // First, identify the structure of the word
    var kanjiPart = ""
    var kanaSuffix = ""
    var isInKanaSuffix = false

    // Build kanji part and kana suffix
    for char in text {
      if !isInKanaSuffix && isKanji(char) {
        kanjiPart.append(char)
      } else if isHiragana(char) || isKatakana(char) {
        isInKanaSuffix = true
        kanaSuffix.append(char)
      } else if isInKanaSuffix {
        // If we hit a non-kana character after starting the suffix, append to suffix
        kanaSuffix.append(char)
      } else {
        // Non-kanji, non-kana character before any kana
        kanjiPart.append(char)
      }
    }

    // If we have a kana suffix, remove it from the reading
    var kanjiReading = reading
    if !kanaSuffix.isEmpty && reading.hasSuffix(kanaSuffix) {
      kanjiReading = String(reading.dropLast(kanaSuffix.count))
    }

    // Build result tokens
    var result: [FuriganaToken] = []

    if !kanjiPart.isEmpty {
      // Only add furigana if there are actual kanji characters
      let needsReading = kanjiPart.contains { isKanji($0) }
      result.append(
        FuriganaToken(
          text: kanjiPart,
          reading: needsReading && !kanjiReading.isEmpty ? kanjiReading : nil
        ))
    }

    if !kanaSuffix.isEmpty {
      result.append(FuriganaToken(text: kanaSuffix, reading: nil))
    }

    return result
  }
  private static func textRequiresFurigana(_ text: String) -> Bool {
    text.contains { isKanji($0) || isKatakana($0) }
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
    guard
      let latinReading = CFStringTokenizerCopyCurrentTokenAttribute(
        tokenizer,
        kCFStringTokenizerAttributeLatinTranscription
      ) as? String
    else {
      return nil
    }

    let hiraganaReading = NSMutableString(string: latinReading)
    CFStringTransform(hiraganaReading, nil, kCFStringTransformLatinHiragana, false)

    return hiraganaReading as String
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
