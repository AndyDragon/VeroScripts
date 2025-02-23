//
//  ScriptEditor.swift
//  Vero Scripts Editor
//
//  Created by Andrew Forget on 2024-02-10.
//

import SwiftUI
import SwiftUIIntrospect
import SystemColors

struct ScriptEditor: View {
    var title: String
    var isFeature: Bool
    @Binding var script: String
    var minHeight: CGFloat
    var maxHeight: CGFloat
    var copy: () -> Void
    var focusedField: FocusState<FocusField?>.Binding
    var editorFocusField: FocusField
    var buttonFocusField: FocusField

    private func color() -> Color {
        if script.count > 963 {
            return .red
        }
        if script.count > 950 {
            return .orange
        }
        return .green
    }

    var body: some View {
        // Header
        HStack {
            Text(title)

            Button(action: {
                copy()
            }, label: {
                Text("Copy")
                    .padding(.horizontal, 20)
            })

            Spacer()

            if isFeature {
                Text("Length: \(script.count) characters out of 963")
                    .foregroundStyle(color())
            }
        }
        .frame(alignment: .leading)
        .padding([.top], 4)

        // Editor
        TextEditor(text: $script)
            .font(.system(size: 14))
            .frame(minWidth: 200, maxWidth: .infinity, minHeight: minHeight, maxHeight: maxHeight)
            .focusable()
            .focused(focusedField, equals: editorFocusField)
            .textEditorStyle(.plain)
            .padding(8)
            .background(Color.textBackground)
            .cornerRadius(6)
            .autocorrectionDisabled(false)
            .disableAutocorrection(false)
            .introspect(.scrollView, on: .macOS(.v14, .v15)) { scrollView in
                scrollView.scrollerStyle = .overlay
                scrollView.autohidesScrollers = true
                scrollView.scrollerStyle = .legacy
            }
    }
}
