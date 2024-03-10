//
//  NewMembershipEditor.swift
//  Vero Scripts
//
//  Created by Andrew Forget on 2024-02-10.
//

import SwiftUI

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
#if os(iOS)
            Text("New membership: ")
#endif
            Picker("New membership: ", selection: $newMembership.onChange(onChanged)) {
                ForEach(NewMembershipCase.casesFor(hub: currentPage?.hub)) { level in
                    Text(level.rawValue)
                        .tag(level)
                        .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                }
            }
            .tint(Color.AccentColor)
            .accentColor(Color.AccentColor)
#if os(iOS)
            .frame(minWidth: 120, alignment: .leading)
#else
            .frame(width: 320)
#endif

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
#if os(iOS)
                .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 80)
#else
                .frame(minWidth: 200, maxWidth: .infinity, minHeight: minHeight, maxHeight: maxHeight)
#endif
                .foregroundStyle(valid ? Color.TextColorPrimary : Color.TextColorRequired, Color.TextColorSecondary)
                .padding(.all, 4)
                .scrollContentBackground(.hidden)
                .background(Color.BackgroundColorEditor)
                .border(Color.gray.opacity(0.25))
                .cornerRadius(5)
                .focused(focus, equals: focusField)
#if !os(iOS)
                .textEditorStyle(.plain)
#endif
        } else {
            TextEditor(text: $script)
                .font(.system(size: 14))
#if os(iOS)
                .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 80)
#else
                .frame(minWidth: 200, maxWidth: .infinity, minHeight: minHeight, maxHeight: maxHeight)
#endif
                .foregroundStyle(valid ? Color.TextColorPrimary : Color.TextColorRequired, Color.TextColorSecondary)
                .padding(.all, 4)
                .scrollContentBackground(.hidden)
                .background(Color.BackgroundColorEditor)
                .border(Color.gray.opacity(0.25))
                .cornerRadius(5)
                .focused(focus, equals: focusField)
        }
    }
}
