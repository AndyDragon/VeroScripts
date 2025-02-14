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
    var currentPage: LoadedPage
    var onChanged: (NewMembershipCase) -> Void
    var valid: Bool
    var canCopy: Bool
    var copy: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text("New membership:")
            
            Picker("", selection: $newMembership.onChange { value in
                onChanged(value)
            }) {
                ForEach(NewMembershipCase.casesFor(hub: currentPage.hub)) { level in
                    Text(level.scriptNewMembershipStringForHub(hub: currentPage.hub))
                        .tag(level)
                        .foregroundStyle(Color(UIColor.label), Color(UIColor.secondaryLabel))
                }
            }
            .tint(Color.accentColor)
            .accentColor(Color.accentColor)
            .foregroundStyle(Color.accentColor, Color(UIColor.label))
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: {
                copy()
            }) {
                Label("Copy", systemImage: "list.clipboard")
                    .padding(.horizontal, 4)
                    .foregroundColor(canCopy ? .primary : .gray)
            }
            .disabled(!canCopy)
            .buttonStyle(.bordered)

            TextEditor(text: $script)
                .font(.system(size: 14))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scrollContentBackground(.hidden)
                .padding(4)
                .background(Color.backgroundColor.opacity(0.5))
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)
                .autocorrectionDisabled(false)
                .disableAutocorrection(false)
        }
    }
}
