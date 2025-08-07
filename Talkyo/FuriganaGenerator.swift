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
    let trimmedReading = removeMatchingSuffixFromReading(originalText: text, reading: reading)

    var result: [FuriganaToken] = []
    var currentSegment = ""
    var currentType: CharacterType?

    for char in text {
      let charType = getCharacterType(char)

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
  private static func removeMatchingSuffixFromReading(originalText: String, reading: String) -> String {
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

    if suffixLength > 0 {
      let suffix = String(textArray.suffix(suffixLength))
      if reading.hasSuffix(suffix) {
        return String(reading.dropLast(suffix.count))
      }
    }

    return reading
  }
  private static func createTokenForSegment(
    text: String, type: CharacterType, fullReading: String, originalText: String
  ) -> FuriganaToken {
    switch type {
    case .kanji:
      return FuriganaToken(text: text, reading: fullReading.isEmpty ? nil : fullReading)
    case .hiragana, .katakana, .other:
      return FuriganaToken(text: text, reading: nil)
    }
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
  private enum CharacterType {
    case kanji
    case hiragana
    case katakana
    case other
  }
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
