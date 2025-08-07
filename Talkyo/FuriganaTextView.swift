import SwiftUI

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

struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Hashable & Identifiable {
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

struct FlexibleViewInternal<Data: Collection, Content: View>: View where Data.Element: Hashable & Identifiable {
  let availableWidth: CGFloat
  let data: Data
  let spacing: CGFloat
  let alignment: HorizontalAlignment
  let content: (Data.Element) -> Content

  @State private var elementsSize: [Data.Element: CGSize] = [:]

  var body: some View {
    VStack(alignment: alignment, spacing: 10) {
      ForEach(Array(computeRows().enumerated()), id: \.offset) { _, rowElements in
        HStack(spacing: spacing) {
          ForEach(rowElements) { element in
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
    if token.needsFurigana, let reading = token.reading {
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
      Text(token.text)
        .font(.custom("KosugiMaru-Regular", size: fontSize))
        .fontWeight(.bold)
        .foregroundColor(textColor)
        .fixedSize()
        .padding(.top, verticalPadding)
    }
  }
}
