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
    var minHeight: CGFloat
    var maxHeight: CGFloat
    var onChanged: (NewMembershipCase) -> Void
    var valid: Bool
    var canCopy: Bool
    var copy: () -> Void
    
    var body: some View {
        HStack {
#if os(iOS)
            Text("New membership: ")
#endif
            Picker("New membership: ", selection: $newMembership.onChange(onChanged)) {
                ForEach(NewMembershipCase.allCases) { level in
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

        TextEditor(text: $script)
            .font(.system(size: 14))
#if os(iOS)
            .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 80)
            .border(.gray)
#else
            .frame(minWidth: 200, maxWidth: .infinity, minHeight: minHeight, maxHeight: maxHeight)
            .padding(2)
            .border(Color.windowBackground)
            .cornerRadius(5)
#endif
            .foregroundColor(valid ? .TextColorPrimary : .TextColorRequired)
            .scrollContentBackground(.hidden)
            .background(Color.BackgroundColorEditor)
    }
}
