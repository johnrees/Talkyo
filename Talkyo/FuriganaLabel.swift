//
//  FuriganaLabel.swift
//  Talkyo
//
//  Custom CoreText view for proper furigana rendering
//

import UIKit
import CoreText

class FuriganaLabel: UIView {
    var text: String = "" { didSet { setNeedsDisplay() } }
    var furigana: String = "" { didSet { setNeedsDisplay() } }
    var fontSize: CGFloat = 32 { didSet { setNeedsDisplay() } }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Flip the coordinate system
        context.textMatrix = .identity
        context.translateBy(x: 0, y: bounds.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        let attributedString = createRubyAttributedString()
        
        // Create framesetter
        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
        
        // Create path
        let path = CGMutablePath()
        path.addRect(bounds)
        
        // Create frame
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attributedString.length), path, nil)
        
        // Draw the frame
        CTFrameDraw(frame, context)
    }
    
    private func createRubyAttributedString() -> NSAttributedString {
        guard !text.isEmpty else {
            return NSAttributedString(string: "話してください", attributes: [
                .font: UIFont.systemFont(ofSize: fontSize * 0.7),
                .foregroundColor: UIColor.secondaryLabel,
                kCTParagraphStyleAttributeName as NSAttributedString.Key: createCenterParagraphStyle()
            ])
        }
        
        guard !furigana.isEmpty else {
            return NSAttributedString(string: text, attributes: [
                .font: UIFont.systemFont(ofSize: fontSize),
                .foregroundColor: UIColor.label,
                kCTParagraphStyleAttributeName as NSAttributedString.Key: createCenterParagraphStyle()
            ])
        }
        
        let result = NSMutableAttributedString()
        let furiganaComponents = furigana.components(separatedBy: " ")
        var textIndex = text.startIndex
        
        for component in furiganaComponents {
            if component.contains("(") && component.contains(")") {
                let parts = component.split(separator: "(", maxSplits: 1)
                if parts.count == 2 {
                    let kanji = String(parts[0])
                    let reading = String(parts[1].dropLast())
                    
                    if let range = text.range(of: kanji, range: textIndex..<text.endIndex) {
                        // Add text before kanji
                        let beforeText = String(text[textIndex..<range.lowerBound])
                        if !beforeText.isEmpty {
                            result.append(NSAttributedString(string: beforeText, attributes: [
                                .font: UIFont.systemFont(ofSize: fontSize),
                                .foregroundColor: UIColor.label
                            ]))
                        }
                        
                        // Add kanji with ruby
                        let rubyAnnotation = CTRubyAnnotationCreateWithAttributes(
                            .auto,
                            .auto,
                            .before,
                            reading as CFString,
                            [:] as CFDictionary
                        )
                        
                        result.append(NSAttributedString(string: kanji, attributes: [
                            .font: UIFont.systemFont(ofSize: fontSize),
                            .foregroundColor: UIColor.label,
                            kCTRubyAnnotationAttributeName as NSAttributedString.Key: rubyAnnotation
                        ]))
                        
                        textIndex = range.upperBound
                    }
                }
            }
        }
        
        // Add remaining text
        if textIndex < text.endIndex {
            let remainingText = String(text[textIndex...])
            result.append(NSAttributedString(string: remainingText, attributes: [
                .font: UIFont.systemFont(ofSize: fontSize),
                .foregroundColor: UIColor.label
            ]))
        }
        
        // Add paragraph style for centering
        let paragraphStyle = createCenterParagraphStyle()
        result.addAttribute(
            kCTParagraphStyleAttributeName as NSAttributedString.Key,
            value: paragraphStyle,
            range: NSRange(location: 0, length: result.length)
        )
        
        return result.length > 0 ? result : NSAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: fontSize),
            .foregroundColor: UIColor.label,
            kCTParagraphStyleAttributeName as NSAttributedString.Key: paragraphStyle
        ])
    }
    
    private func createCenterParagraphStyle() -> CTParagraphStyle {
        var alignment = CTTextAlignment.center
        let alignmentSetting = CTParagraphStyleSetting(
            spec: .alignment,
            valueSize: MemoryLayout<CTTextAlignment>.size,
            value: &alignment
        )
        
        let settings = [alignmentSetting]
        return CTParagraphStyleCreate(settings, settings.count)
    }
}