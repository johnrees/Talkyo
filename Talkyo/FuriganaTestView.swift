//
//  FuriganaTestView.swift
//  Talkyo
//
//  Test view for verifying furigana display with various Japanese texts
//

import SwiftUI

struct FuriganaTestView: View {
    let testCases = [
        "彼は先生ですか？",
        "今日は天気がいいですね。",
        "私は日本語を勉強しています。",
        "東京タワーに行きたいです。",
        "美味しい寿司を食べました。",
        "新幹線で京都へ行きます。",
        "漢字の読み方は難しいです。",
        "春夏秋冬、日本には四季があります。",
        "富士山は日本一高い山です。",
        "お元気ですか？元気です！"
    ]
    
    @State private var selectedIndex = 0
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Furigana Display Test")
                .font(.largeTitle)
                .padding()
            
            Picker("Test Case", selection: $selectedIndex) {
                ForEach(0..<testCases.count, id: \.self) { index in
                    Text("Example \(index + 1)").tag(index)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 100)
            
            VStack(spacing: 20) {
                Text("Original Text:")
                    .font(.headline)
                Text(testCases[selectedIndex])
                    .font(.title2)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                Text("With Furigana:")
                    .font(.headline)
                    .padding(.top)
                
                let tokens = FuriganaGenerator.generateTokens(for: testCases[selectedIndex])
                FuriganaTextView(
                    tokens: tokens,
                    fontSize: 32,
                    textColor: .primary
                )
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .frame(maxHeight: 150)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .navigationTitle("Furigana Test")
    }
}

#Preview {
    NavigationView {
        FuriganaTestView()
    }
}