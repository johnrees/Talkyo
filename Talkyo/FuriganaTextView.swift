//
//  FuriganaTextView.swift
//  Talkyo
//
//  SwiftUI implementation for displaying furigana (ruby text) above kanji
//  Uses a simple and reliable approach with Text overlays
//

import SwiftUI

// MARK: - Furigana Text View

/// A SwiftUI view that displays Japanese text with furigana (small hiragana) above kanji characters
struct FuriganaTextView: View {
    let tokens: [FuriganaToken]
    let fontSize: CGFloat
    let textColor: Color
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tokens.enumerated()), id: \.offset) { _, token in
                FuriganaCharacterView(
                    token: token,
                    fontSize: fontSize,
                    textColor: textColor
                )
            }
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Furigana Character View

/// Individual character/token view that displays furigana above the base text when needed
private struct FuriganaCharacterView: View {
    let token: FuriganaToken
    let fontSize: CGFloat
    let textColor: Color
    
    private var furiganaSize: CGFloat {
        fontSize * 0.5
    }
    
    private var verticalPadding: CGFloat {
        fontSize * 0.6
    }
    
    var body: some View {
        if token.needsFurigana, let reading = token.reading {
            // Display with furigana above
            VStack(spacing: 0) {
                Text(reading)
                    .font(.system(size: furiganaSize))
                    .foregroundColor(textColor.opacity(0.8))
                    .lineLimit(1)
                
                Text(token.text)
                    .font(.system(size: fontSize))
                    .foregroundColor(textColor)
                    .lineLimit(1)
            }
        } else {
            // Display without furigana (aligned with furigana text)
            Text(token.text)
                .font(.system(size: fontSize))
                .foregroundColor(textColor)
                .lineLimit(1)
                .padding(.top, verticalPadding)
        }
    }
}