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

    private func color() -> Color {
        if script.count > 1000 {
            return .red
        }
        if script.count >= 990 {
            return .orange
        }
        return .green
    }

    var body: some View {
        // Header
        HStack {
            Text(title)

            Button(action: {
                copy(true, false)
            }) {
                Label("Copy", systemImage: "list.clipboard")
                    .padding(.horizontal, 4)
            }
            .disabled(!canCopy)

            Button(action: {
                copy(false, true)
            }, label: {
                Label("Copy (with Placeholders)", systemImage: "list.bullet.clipboard")
                    .padding(.horizontal, 4)
            })
            .disabled(!hasPlaceholders)

            Spacer()

            if canCopy && script.count >= 975 {
                Text("Length: \(script.count) characters out of 1000\(hasPlaceholders ? " **" : "")")
                    .foregroundStyle(color())
            }
        }
        .frame(alignment: .leading)
        .padding([.top], 4)

        // Editor
        if #available(macOS 14.0, *) {
            TextEditor(text: $script)
                .font(.system(size: 14))
                .frame(minWidth: 200, maxWidth: .infinity, minHeight: minHeight, maxHeight: maxHeight)
                .focused(focus, equals: focusField)
                .textEditorStyle(.plain)
                .foregroundStyle(canCopy ? Color.label : Color.red, Color.secondaryLabel)
                .scrollContentBackground(.hidden)
                .padding(4)
                .background(Color.controlBackground.opacity(0.5))
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)
                .padding([.bottom], 6)
        } else {
            TextEditor(text: $script)
                .font(.system(size: 14))
                .frame(minWidth: 200, maxWidth: .infinity, minHeight: minHeight, maxHeight: maxHeight)
                .focused(focus, equals: focusField)
                .foregroundStyle(canCopy ? Color.label : Color.red, Color.secondaryLabel)
                .scrollContentBackground(.hidden)
                .padding(4)
                .background(Color.controlBackground.opacity(0.5))
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)
                .padding([.bottom], 6)
        }
    }
}
