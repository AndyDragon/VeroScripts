//
//  EditorState.swift
//  Vero Scripts Editor
//
//  Created by Andrew Forget on 2024-12-31.
//

import SwiftUI

let staticPlaceholders = [
    "PAGENAME",
    "FULLPAGENAME",
    "PAGETITLE",
    "PAGEHASH",
    "USERNAME",
    "MEMBERLEVEL",
    "YOURNAME",
    "YOURFIRSTNAME",
    "STAFFLEVEL"
]
let allStaticPlaceholderPattern = "%%(.*?)%%"
let staticPlaceholderPattern = "%%(" + staticPlaceholders.joined(separator: "|") + ")%%"
let shortManualPlaceholderPattern = "\\[\\[(.*?)\\]\\]"
let longManualPlaceholderPattern = "\\[\\{(.*?)\\}\\]"
let hastagPattern = "(#|@)[^\\s]*"

let monospaceFont = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
let monospaceBoldFont = NSFont.monospacedSystemFont(ofSize: 14, weight: .bold)
let defaultText: [NSAttributedString.Key : Any] = [
    .font: monospaceFont,
    .foregroundColor: NSColor(red: 1, green: 1, blue: 1, alpha: 1)
]
let errorText: [NSAttributedString.Key : Any] = [
    .font: monospaceBoldFont,
    .foregroundColor: NSColor(red: 1, green: 0, blue: 0, alpha: 1)
]
let staticPlaceholderText: [NSAttributedString.Key : Any] = [
    .font: monospaceBoldFont,
    .foregroundColor: NSColor(red: 1, green: 0.4, blue: 1, alpha: 1)
]
let shortManualPlaceholderText: [NSAttributedString.Key : Any] = [
    .font: monospaceBoldFont,
    .foregroundColor: NSColor(red: 0.4, green: 1, blue: 1, alpha: 1)
]
let longManualPlaceholderText: [NSAttributedString.Key : Any] = [
    .font: monospaceBoldFont,
    .foregroundColor: NSColor(red: 0.4, green: 1, blue: 0.4, alpha: 1)
]
let hastagText: [NSAttributedString.Key : Any] = [
    .font: monospaceFont,
    .foregroundColor: NSColor(red: 0.8, green: 0.9, blue: 1, alpha: 1)
]

class EditorState<T>: NSObject, NSTextViewDelegate where T: Identifiable {
    var textView: NSTextView?
    var contextId: T.ID?
    var onTextChanged: (_ text: String, _ contextId: T.ID?) -> Void = { _, _ in }
    
    func updateHighlighting() {
        if let textView, let text = textView.textStorage?.string {
            let wholeRange = NSRange(text.startIndex..<text.endIndex, in: text)
            textView.textStorage?.setAttributes(defaultText, range: wholeRange)
            
            let hastags = text.enumeratePattern(using: hastagPattern)
            for hastag in hastags {
                let nsRange = NSRange(hastag, in: text)
                textView.textStorage?.setAttributes(hastagText, range: nsRange)
            }
            let staticAllPlaceholders = text.enumeratePattern(using: allStaticPlaceholderPattern)
            for placeholder in staticAllPlaceholders {
                let nsRange = NSRange(placeholder, in: text)
                textView.textStorage?.setAttributes(errorText, range: nsRange)
            }
            let staticPlaceholders = text.enumeratePattern(using: staticPlaceholderPattern)
            for placeholder in staticPlaceholders {
                let nsRange = NSRange(placeholder, in: text)
                textView.textStorage?.setAttributes(staticPlaceholderText, range: nsRange)
            }
            let shortManualPlaceholders = text.enumeratePattern(using: shortManualPlaceholderPattern)
            for placeholder in shortManualPlaceholders {
                let nsRange = NSRange(placeholder, in: text)
                textView.textStorage?.setAttributes(shortManualPlaceholderText, range: nsRange)
            }
            let longManualPlaceholders = text.enumeratePattern(using: longManualPlaceholderPattern)
            for placeholder in longManualPlaceholders {
                let nsRange = NSRange(placeholder, in: text)
                textView.textStorage?.setAttributes(longManualPlaceholderText, range: nsRange)
            }
            textView.typingAttributes = defaultText
        }
    }
    
    func textDidChange(_ notification: Notification) {
        onTextChanged(textView?.textStorage?.string ?? "", contextId)
        updateHighlighting()
    }
    
    func pasteTextToEditor(_ textToPaste: String) {
        if let textView {
            if textView.shouldChangeText(in: textView.selectedRange(), replacementString: textToPaste) {
                textView.breakUndoCoalescing()
                textView.undoManager?.beginUndoGrouping()
                textView.textStorage?.beginEditing()
                textView.textStorage?.replaceCharacters(in: textView.selectedRange(), with: textToPaste)
                textView.textStorage?.endEditing()
                textView.undoManager?.endUndoGrouping()
                textView.breakUndoCoalescing()
            }
        }
        onTextChanged(textView?.textStorage?.string ?? "", contextId)
        updateHighlighting()
    }

    func resetText(_ newText: String, clearUndo: Bool = true) {
        if let textView, let text = textView.textStorage?.string {
            let wholeRange = NSRange(text.startIndex..<text.endIndex, in: text)
            if textView.shouldChangeText(in: wholeRange, replacementString: newText) {
                textView.breakUndoCoalescing()
                textView.undoManager?.beginUndoGrouping()
                textView.textStorage?.beginEditing()
                textView.textStorage?.replaceCharacters(in: wholeRange, with: newText)
                textView.textStorage?.endEditing()
                textView.undoManager?.endUndoGrouping()
                textView.breakUndoCoalescing()
                if clearUndo {
                    textView.undoManager?.removeAllActions()
                }
            }
        }
        onTextChanged(textView?.textStorage?.string ?? "", contextId)
        updateHighlighting()
    }
}
