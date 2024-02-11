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
    var copy: (Bool, Bool) -> Void
    
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
            Button(action: {
                copy(false, true)
            }, label: {
                Text("Copy (with Placeholders)")
                    .padding(.horizontal, 20)
            })
            Spacer()
        }
        .frame(alignment: .leading)
        .padding([.top], 4)

        // Editor
        TextEditor(text: $script)
            .font(.system(size: 14))
#if os(iOS)
            .frame(maxWidth: .infinity, minHeight: minHeight, maxHeight: maxHeight)
            .colorMultiply(Color(
                red: ColorScheme == .dark ? 1.05 : 0.95,
                green: ColorScheme == .dark ? 1.05 : 0.95,
                blue: ColorScheme == .dark ? 1.05 : 0.95))
            .border(.gray)
#else
            .frame(minWidth: 200, maxWidth: .infinity, minHeight: minHeight, maxHeight: maxHeight)
#endif
            .padding([.bottom], 6)
    }
}
