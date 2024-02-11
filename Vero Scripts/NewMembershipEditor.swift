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
    var onChanged: (NewMembershipCase) -> Void
    var copy: () -> Void
    
    var body: some View {
        HStack {
#if os(iOS)
            Text("New membership: ")
#endif
            Picker("New membership: ", selection: $newMembership.onChange(onChanged)) {
                ForEach(NewMembershipCase.allCases) { level in
                    Text(level.rawValue).tag(level)
                }
            }
            .frame(width: 320)
            
            Button(action: {
                copy()
            }, label: {
                Text("Copy")
                    .padding(.horizontal, 20)
            })
            Spacer()
        }
        .frame(alignment: .leading)
        .padding([.top], 4)

        TextEditor(text: $script)
#if os(iOS)
            .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 80)
            .colorMultiply(Color(
                red: ColorScheme == .dark ? 1.05 : 0.95,
                green: ColorScheme == .dark ? 1.05 : 0.95,
                blue: ColorScheme == .dark ? 1.05 : 0.95))
            .border(.gray)
#else
            .frame(minWidth: 200, maxWidth: .infinity, minHeight: 80, maxHeight: 160)
#endif
    }
}
