//
//  FieldEditor.swift
//  Vero Scripts
//
//  Created by Andrew Forget on 2024-02-10.
//

import SwiftUI

struct FieldEditor: View {
    var title: String
    var titleWidth: [CGFloat] = []
    var placeholder: String
    @Binding var field: String
    var fieldChanged: (_ to: String) -> Void
    var validate: (String) -> Bool = { value in value.count != 0 }
    
    var body: some View {
        // Title
        if titleWidth.isEmpty {
            Text(title)
                .foregroundColor(.labelColor(validate(field)))
        } else {
            Text(title)
                .foregroundColor(.labelColor(validate(field)))
#if os(iOS)
                .frame(width: titleWidth[1], alignment: .leading)
#else
                .frame(width: titleWidth[0], alignment: .leading)
#endif
        }
        
        // Editor
        TextField(
            placeholder,
            text: $field.onChange(fieldChanged)
        )
#if os(iOS)
        .textInputAutocapitalization(.never)
#endif
    }
}
