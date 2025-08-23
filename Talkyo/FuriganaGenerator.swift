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
    // Split text into segments by character type (kanji vs kana)
    var segments: [(text: String, isKanji: Bool)] = []
    var currentSegment = ""
    var currentIsKanji: Bool? = nil

    for char in text {
      let charIsKanji = isKanji(char)

      if let prevIsKanji = currentIsKanji, prevIsKanji != charIsKanji {
        // Character type changed, save current segment
        segments.append((text: currentSegment, isKanji: prevIsKanji))
        currentSegment = String(char)
        currentIsKanji = charIsKanji
      } else {
        currentSegment.append(char)
        currentIsKanji = charIsKanji
      }
    }

    // Add the last segment
    if !currentSegment.isEmpty, let isKanji = currentIsKanji {
      segments.append((text: currentSegment, isKanji: isKanji))
    }

    // Now match the reading to the segments
    var result: [FuriganaToken] = []
    var readingChars = Array(reading)
    var readingIndex = 0

    for (i, segment) in segments.enumerated() {
      if segment.isKanji {
        // For kanji segments, we need to figure out their reading
        // Look for the next kana segment to use as boundary
        let nextKanaSegment = segments.dropFirst(i + 1).first(where: { !$0.isKanji })

        if let nextKana = nextKanaSegment {
          // Find where this kana appears in the remaining reading
          let remainingReading = String(readingChars[readingIndex...])
          if let kanaIndex = remainingReading.firstIndex(of: nextKana.text.first!) {
            let offset = remainingReading.distance(from: remainingReading.startIndex, to: kanaIndex)
            // Check if the full kana segment matches
            let potentialMatch = String(
              readingChars[readingIndex..<min(readingIndex + offset + nextKana.text.count, readingChars.count)])
            if potentialMatch.hasSuffix(nextKana.text) {
              // The reading for this kanji is everything up to where the kana starts
              let kanjiReading = String(readingChars[readingIndex..<readingIndex + offset])
              result.append(FuriganaToken(text: segment.text, reading: kanjiReading.isEmpty ? nil : kanjiReading))
              readingIndex = readingIndex + offset
            } else {
              // Couldn't match properly, give this segment the remaining reading
              let kanjiReading = String(readingChars[readingIndex...])
              result.append(FuriganaToken(text: segment.text, reading: kanjiReading.isEmpty ? nil : kanjiReading))
              readingIndex = readingChars.count
            }
          } else {
            // Kana not found, this kanji gets all remaining reading
            let kanjiReading = String(readingChars[readingIndex...])
            result.append(FuriganaToken(text: segment.text, reading: kanjiReading.isEmpty ? nil : kanjiReading))
            readingIndex = readingChars.count
          }
        } else {
          // No more kana segments, this kanji gets the rest of the reading
          let kanjiReading = String(readingChars[readingIndex...])
          result.append(FuriganaToken(text: segment.text, reading: kanjiReading.isEmpty ? nil : kanjiReading))
          readingIndex = readingChars.count
        }
      } else {
        // For kana segments, no furigana needed
        result.append(FuriganaToken(text: segment.text, reading: nil))
        // Advance reading index past this kana
        readingIndex = min(readingIndex + segment.text.count, readingChars.count)
      }
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
