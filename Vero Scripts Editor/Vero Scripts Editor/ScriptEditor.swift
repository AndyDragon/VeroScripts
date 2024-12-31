//
//  ScriptEditor.swift
//  Vero Scripts Editor
//
//  Created by Andrew Forget on 2024-02-10.
//

import SwiftUI
import SystemColors

struct ScriptEditor: View {
    var title: String
    @Binding var script: String
    var minHeight: CGFloat
    var maxHeight: CGFloat
    var focusedField: FocusState<FocusField?>.Binding
    var editorFocusField: FocusField
    var buttonFocusField: FocusField

    var body: some View {
        // Header
        HStack {
            Text(title)

            Spacer()
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
    }
}
