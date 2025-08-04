//
//  RubyTextView.swift
//  Talkyo
//
//  Custom view for displaying Japanese text with furigana above kanji
//

import SwiftUI
import UIKit

struct RubyTextView: UIViewRepresentable {
    let text: String
    let furigana: String
    let fontSize: CGFloat
    
    func makeUIView(context: Context) -> FuriganaLabel {
        let label = FuriganaLabel()
        label.backgroundColor = .clear
        label.isOpaque = false
        return label
    }
    
    func updateUIView(_ label: FuriganaLabel, context: Context) {
        label.text = text
        label.furigana = furigana
        label.fontSize = fontSize
    }
}

struct RubyTextContainer: View {
    let text: String
    let furigana: String
    
    var body: some View {
        if text.isEmpty {
            Text("話してください")
                .font(.title2)
                .foregroundColor(.gray)
                .padding()
        } else {
            RubyTextView(text: text, furigana: furigana, fontSize: 32)
                .frame(maxWidth: .infinity)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}