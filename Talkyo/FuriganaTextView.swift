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

/// Individual character/token view that displays furigana above the base text when needed
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
    
    var body: some View {
        VStack(spacing: 0) {
            // Pitch accent indicators above furigana/text
            if token.hasPitchAccent {
                PitchAccentView(
                    token: token,
                    fontSize: furiganaSize,
                    baseWidth: token.needsFurigana ? nil : fontSize
                )
            }
            
            if token.needsFurigana, let reading = token.reading {
                // Display with furigana above
                VStack(spacing: 0) {
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
                }
            } else {
                // Display without furigana (aligned with furigana text)
                Text(token.text)
                    .font(.custom("KosugiMaru-Regular", size: fontSize))
                    .fontWeight(.bold)
                    .foregroundColor(textColor)
                    .fixedSize()
                    .padding(.top, token.hasPitchAccent ? 0 : verticalPadding)
            }
        }
    }
}

// MARK: - Pitch Accent View

/// Displays pitch accent indicators above/below text
struct PitchAccentView: View {
    let token: FuriganaToken
    let fontSize: CGFloat
    let baseWidth: CGFloat?
    
    private var accentLineHeight: CGFloat {
        fontSize * 0.1
    }
    
    private var accentLineSpacing: CGFloat {
        fontSize * 0.05
    }
    
    var body: some View {
        if let pitchPattern = token.pitchPattern, !pitchPattern.isEmpty {
            HStack(spacing: 0) {
                ForEach(Array(pitchPattern.enumerated()), id: \.offset) { index, pitch in
                    VStack(spacing: accentLineSpacing) {
                        // High pitch indicator (line above)
                        Rectangle()
                            .fill(pitch == 1 ? Color.blue : Color.clear)
                            .frame(width: characterWidth(for: index), height: accentLineHeight)
                        
                        // Space for the actual text
                        Color.clear
                            .frame(height: fontSize * 0.2)
                        
                        // Low pitch indicator (line below)  
                        Rectangle()
                            .fill(pitch == 0 ? Color.red : Color.clear)
                            .frame(width: characterWidth(for: index), height: accentLineHeight)
                    }
                }
            }
        }
    }
    
    private func characterWidth(for index: Int) -> CGFloat {
        if let baseWidth = baseWidth {
            // For text without furigana, use proportional width based on base font
            return baseWidth / CGFloat(token.pitchPattern?.count ?? 1)
        } else {
            // For text with furigana, use furigana font size as base
            return fontSize * 0.8
        }
    }
}

// MARK: - Token Hashable Extension

extension FuriganaToken: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(text)
        hasher.combine(reading)
        hasher.combine(pitchAccent?.accentPosition)
    }
}