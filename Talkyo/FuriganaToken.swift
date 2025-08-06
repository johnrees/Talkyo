import Foundation

struct FuriganaToken: Equatable, Hashable, Sendable {
    let text: String
    let reading: String?
    var needsFurigana: Bool {
        guard let reading = reading else { return false }
        return reading != text && containsKanji
    }
    private var containsKanji: Bool {
        text.contains { isKanji($0) }
    }
    private func isKanji(_ character: Character) -> Bool {
        guard let unicodeScalar = character.unicodeScalars.first else {
            return false
        }
        let kanjiRange = 0x4E00...0x9FFF
        return kanjiRange.contains(Int(unicodeScalar.value))
    }
}