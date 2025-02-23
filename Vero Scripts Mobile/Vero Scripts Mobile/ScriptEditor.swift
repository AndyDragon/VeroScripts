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
        VStack(alignment: .leading) {
            // Header
            Text(title)

            Button(action: {
                copy(true, false)
            }) {
                Label("Copy", systemImage: "list.clipboard")
                    .padding(.horizontal, 4)
            }
            .buttonStyle(.bordered)

            if script.count >= 975 {
                Text("Length: \(script.count) characters out of 1000\(hasPlaceholders ? " **" : "")")
                    .foregroundStyle(color())
            }

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
