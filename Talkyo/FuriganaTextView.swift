//
//  FuriganaTextView.swift
//  Talkyo
//
//  SwiftUI implementation for displaying furigana using Text overlays
//

import SwiftUI

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

struct FuriganaCharacterView: View {
    let token: FuriganaToken
    let fontSize: CGFloat
    let textColor: Color
    
    var body: some View {
        if token.needsFurigana, let reading = token.reading {
            VStack(spacing: 0) {
                Text(reading)
                    .font(.system(size: fontSize * 0.5))
                    .foregroundColor(textColor.opacity(0.8))
                    .lineLimit(1)
                
                Text(token.text)
                    .font(.system(size: fontSize))
                    .foregroundColor(textColor)
                    .lineLimit(1)
            }
        } else {
            Text(token.text)
                .font(.system(size: fontSize))
                .foregroundColor(textColor)
                .lineLimit(1)
                .padding(.top, fontSize * 0.6)
        }
    }
}