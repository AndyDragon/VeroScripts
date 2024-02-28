//
//  ScriptEditor.swift
//  Vero Scripts
//
//  Created by Andrew Forget on 2024-02-10.
//

import SwiftUI

struct ScriptEditor: View {
    var title: String
    @Binding var script: String
    var minHeight: CGFloat
    var maxHeight: CGFloat
    var canCopy: Bool
    var hasPlaceholders: Bool
    var copy: (Bool, Bool) -> Void
    var focus: FocusState<FocusedField?>.Binding
    var focusField: FocusedField

    var body: some View {        
        // Header
        HStack {
            Text(title)

            Button(action: {
                copy(true, false)
            }, label: {
                Text("Copy")
                    .padding(.horizontal, 20)
            })
            .disabled(!canCopy)

            Button(action: {
                copy(false, true)
            }, label: {
                Text("Copy (with Placeholders)")
                    .padding(.horizontal, 20)
            })
            .disabled(!hasPlaceholders)

            Spacer()
        }
        .frame(alignment: .leading)
        .padding([.top], 4)

        // Editor
        TextEditor(text: $script)
            .font(.system(size: 14))
#if os(iOS)
            .frame(maxWidth: .infinity, minHeight: minHeight, maxHeight: maxHeight)
            .border(.gray)
#else
            .frame(minWidth: 200, maxWidth: .infinity, minHeight: minHeight, maxHeight: maxHeight)
#endif
            .foregroundStyle(canCopy ? Color.TextColorPrimary : Color.TextColorRequired, Color.TextColorSecondary)
            .scrollContentBackground(.hidden)
            .background(Color.BackgroundColorEditor)
            .border(Color.windowBackground)
            .cornerRadius(5)
            .padding([.bottom], 6)
            .focused(focus, equals: focusField)
    }
}
