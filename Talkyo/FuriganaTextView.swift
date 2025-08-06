//
//  FuriganaTextView.swift
//  Talkyo
//
//  SwiftUI implementation for displaying furigana (ruby text) above kanji
//  Uses a flexible layout that supports multi-line text
//

import SwiftUI

// MARK: - Furigana Text View

/// A SwiftUI view that displays Japanese text with furigana (small hiragana) above kanji characters
struct FuriganaTextView: View {
    let tokens: [FuriganaToken]
    let fontSize: CGFloat
    let textColor: Color
    
    var body: some View {
        FlexibleView(
            data: tokens,
            spacing: 0,
            alignment: .center
        ) { token in
            FuriganaCharacterView(
                token: token,
                fontSize: fontSize,
                textColor: textColor
            )
        }
    }
}

// MARK: - Flexible View

/// A view that arranges its children in a flow layout, wrapping to new lines as needed
struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content
    
    @State private var availableWidth: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: Alignment(horizontal: alignment, vertical: .top)) {
            Color.clear
                .frame(height: 1)
                .readSize { size in
                    availableWidth = size.width
                }
            
            FlexibleViewInternal(
                availableWidth: availableWidth,
                data: data,
                spacing: spacing,
                alignment: alignment,
                content: content
            )
        }
    }
}

struct FlexibleViewInternal<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let availableWidth: CGFloat
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content
    
    @State private var elementsSize: [Data.Element: CGSize] = [:]
    
    var body: some View {
        VStack(alignment: alignment, spacing: 10) {
            ForEach(computeRows(), id: \.self) { rowElements in
                HStack(spacing: spacing) {
                    ForEach(rowElements, id: \.self) { element in
                        content(element)
                            .readSize { size in
                                elementsSize[element] = size
                            }
                    }
                }
            }
        }
    }
    
    private func computeRows() -> [[Data.Element]] {
        var rows: [[Data.Element]] = [[]]
        var currentRow = 0
        var remainingWidth = availableWidth
        
        for element in data {
            let elementSize = elementsSize[element] ?? CGSize(width: 50, height: 50)
            
            if remainingWidth - elementSize.width >= 0 {
                rows[currentRow].append(element)
                remainingWidth -= elementSize.width + spacing
            } else {
                currentRow += 1
                rows.append([element])
                remainingWidth = availableWidth - elementSize.width - spacing
            }
        }
        
        return rows
    }
}

// MARK: - Size Reader

extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

// MARK: - Furigana Character View

/// Individual character/token view that displays furigana above the base text and pitch accent markings
struct FuriganaCharacterView: View {
    let token: FuriganaToken
    let fontSize: CGFloat
    let textColor: Color
    
    private var furiganaSize: CGFloat {
        fontSize * 0.5
    }
    
    private var verticalPadding: CGFloat {
        fontSize * 0.6
    }
    
    private var pitchAccentLineHeight: CGFloat {
        2.0
    }
    
    var body: some View {
        VStack(spacing: 2) {
            // Pitch accent high indicators (above furigana/text)
            if token.hasPitchAccent {
                PitchAccentHighView(
                    token: token,
                    width: textWidth,
                    height: pitchAccentLineHeight,
                    color: textColor.opacity(0.6)
                )
            } else {
                // Empty space to maintain alignment
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: pitchAccentLineHeight)
            }
            
            if token.needsFurigana, let reading = token.reading {
                // Display with furigana above
                Text(reading)
                    .font(.custom("KosugiMaru-Regular", size: furiganaSize))
                    .fontWeight(.semibold)
                    .foregroundColor(textColor.opacity(0.8))
                    .fixedSize()
                
                Text(token.text)
                    .font(.custom("KosugiMaru-Regular", size: fontSize))
                    .fontWeight(.bold)
                    .foregroundColor(textColor)
                    .fixedSize()
            } else {
                // Single text element (with proper spacing)
                VStack(spacing: 0) {
                    // Empty space equivalent to furigana height
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: furiganaSize * 1.2)
                    
                    Text(token.text)
                        .font(.custom("KosugiMaru-Regular", size: fontSize))
                        .fontWeight(.bold)
                        .foregroundColor(textColor)
                        .fixedSize()
                }
            }
            
            // Pitch accent low indicators (below text)
            if token.hasPitchAccent {
                PitchAccentLowView(
                    token: token,
                    width: textWidth,
                    height: pitchAccentLineHeight,
                    color: textColor.opacity(0.6)
                )
            } else {
                // Empty space to maintain alignment
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: pitchAccentLineHeight)
            }
        }
    }
    
    // Calculate approximate text width for pitch accent lines
    private var textWidth: CGFloat {
        // Use the display text (original text or reading if showing furigana)
        let displayText = token.needsFurigana ? (token.reading ?? token.text) : token.text
        // Rough approximation: Japanese characters are typically wider than Latin characters
        return CGFloat(displayText.count) * fontSize * 0.8
    }
}

// MARK: - Pitch Accent Views

/// View for displaying high pitch accent lines above text
struct PitchAccentHighView: View {
    let token: FuriganaToken
    let width: CGFloat
    let height: CGFloat
    let color: Color
    
    var body: some View {
        HStack(spacing: 0) {
            if let pattern = token.pitchPattern, pattern.hasPitchData {
                ForEach(Array(pattern.pitches.enumerated()), id: \.offset) { index, pitch in
                    Rectangle()
                        .fill(pitch == 1 ? color : Color.clear)
                        .frame(width: width / CGFloat(pattern.pitches.count), height: height)
                }
            } else {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: width, height: height)
            }
        }
    }
}

/// View for displaying low pitch accent lines below text
struct PitchAccentLowView: View {
    let token: FuriganaToken
    let width: CGFloat
    let height: CGFloat
    let color: Color
    
    var body: some View {
        HStack(spacing: 0) {
            if let pattern = token.pitchPattern, pattern.hasPitchData {
                ForEach(Array(pattern.pitches.enumerated()), id: \.offset) { index, pitch in
                    Rectangle()
                        .fill(pitch == 0 ? color : Color.clear)
                        .frame(width: width / CGFloat(pattern.pitches.count), height: height)
                }
            } else {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: width, height: height)
            }
        }
    }
}

// MARK: - Token Hashable Extension

extension FuriganaToken: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(text)
        hasher.combine(reading)
        hasher.combine(pitchPattern?.pitches)
        hasher.combine(pitchPattern?.accentPosition)
    }
}