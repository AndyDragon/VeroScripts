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
    var hasPlaceholders: Bool
    var copy: (Bool, Bool) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            // Header
            Text(title)

            Button(action: {
                copy(true, false)
            }) {
                Text("Copy")
                    .padding(.horizontal, 20)
            }
            .buttonStyle(.bordered)

            // Editor
            TextEditor(text: $script)
                .font(.system(size: 14))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scrollContentBackground(.hidden)
                .padding(4)
                .background(Color.backgroundColor.opacity(0.5))
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)
                .padding([.bottom], 6)
                .autocorrectionDisabled(false)
                .disableAutocorrection(false)
        }
    }
}
