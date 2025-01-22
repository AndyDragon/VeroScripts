//
//  NewMembershipEditor.swift
//  Vero Scripts
//
//  Created by Andrew Forget on 2024-02-10.
//

import SwiftUI
import SystemColors

struct NewMembershipEditor: View {
    @Binding var newMembership: NewMembershipCase
    @Binding var script: String
    @Binding var currentPage: LoadedPage?
    var minHeight: CGFloat
    var maxHeight: CGFloat
    var onChanged: (NewMembershipCase) -> Void
    var valid: Bool
    var canCopy: Bool
    var copy: () -> Void
    var focus: FocusState<FocusedField?>.Binding
    var focusField: FocusedField

    var body: some View {
        HStack {
            Text("New membership:")

            Picker("", selection: $newMembership.onChange(onChanged)) {
                ForEach(NewMembershipCase.casesFor(hub: currentPage?.hub)) { level in
                    Text(level.rawValue)
                        .tag(level)
                        .foregroundStyle(Color.label, Color.secondaryLabel)
                }
            }
            .tint(Color.accentColor)
            .accentColor(Color.accentColor)
            .foregroundStyle(Color.accentColor, Color.label)
            .frame(width: 320)

            Button(action: {
                copy()
            }, label: {
                Text("Copy")
                    .padding(.horizontal, 20)
            })
            .disabled(!canCopy)
            
            Spacer()
        }
        .frame(alignment: .leading)
        .padding([.top], 4)

        if #available(macOS 14.0, *) {
            TextEditor(text: $script)
                .font(.system(size: 14))
                .frame(minWidth: 200, maxWidth: .infinity, minHeight: minHeight, maxHeight: maxHeight)
                .focused(focus, equals: focusField)
                .textEditorStyle(.plain)
                .foregroundStyle(valid ? Color.label : Color.red, Color.secondaryLabel)
                .scrollContentBackground(.hidden)
                .padding(4)
                .background(Color.controlBackground.opacity(0.5))
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)
        } else {
            TextEditor(text: $script)
                .font(.system(size: 14))
                .frame(minWidth: 200, maxWidth: .infinity, minHeight: minHeight, maxHeight: maxHeight)
                .focused(focus, equals: focusField)
                .foregroundStyle(valid ? Color.label : Color.red, Color.secondaryLabel)
                .scrollContentBackground(.hidden)
                .padding(4)
                .background(Color.controlBackground.opacity(0.5))
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)
        }
    }
}
