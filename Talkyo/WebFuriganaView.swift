//
//  WebFuriganaView.swift
//  Talkyo
//
//  WebView implementation for displaying furigana using HTML ruby tags
//

import SwiftUI
import WebKit

struct WebFuriganaView: UIViewRepresentable {
    let tokens: [FuriganaToken]
    let fontSize: CGFloat
    let textColor: UIColor
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let html = generateHTML()
        webView.loadHTMLString(html, baseURL: nil)
    }
    
    private func generateHTML() -> String {
        let colorHex = textColor.toHexString()
        let rubyHTML = tokens.map { token in
            if token.needsFurigana, let reading = token.reading {
                return "<ruby>\(token.text)<rt>\(reading)</rt></ruby>"
            } else {
                return token.text
            }
        }.joined()
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    margin: 0;
                    padding: 20px;
                    background-color: transparent;
                    text-align: center;
                    font-family: -apple-system, system-ui;
                }
                .content {
                    font-size: \(fontSize)px;
                    color: \(colorHex);
                    line-height: 2.0;
                }
                ruby {
                    ruby-align: center;
                }
                rt {
                    font-size: 50%;
                    color: \(colorHex)CC;
                }
            </style>
        </head>
        <body>
            <div class="content">\(rubyHTML)</div>
        </body>
        </html>
        """
    }
}

private extension UIColor {
    func toHexString() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb = Int(r * 255) << 16 | Int(g * 255) << 8 | Int(b * 255) << 0
        
        return String(format: "#%06x", rgb)
    }
}