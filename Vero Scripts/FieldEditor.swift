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
    @Binding var fieldValidation: (valid: Bool, reason: String?)
    var validate: (String) -> (valid: Bool, reason: String?) = { value in
        if value.count == 0 {
            return (false, "Required value")
        }
        return (true, nil)
    }
    var focus: FocusState<FocusedField?>.Binding
    var focusField: FocusedField
    
    var body: some View {
        HStack {
            // Title validator
            if !fieldValidation.valid {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .help(fieldValidation.reason ?? "")
                    .imageScale(.small)
            }
            
            // Title
            if title.count != 0 {
                if titleWidth.isEmpty {
                    Text(title)
                        .foregroundColor(.labelColor(fieldValidation.valid))
#if os(iOS)
                        .lineLimit(1)
                        .truncationMode(.tail)
#endif
                } else {
                    Text(title)
                        .foregroundColor(.labelColor(fieldValidation.valid))
#if os(iOS)
                        .frame(width: titleWidth[1], alignment: .leading)
                        .lineLimit(1)
                        .truncationMode(.tail)
#else
                        .frame(width: titleWidth[0], alignment: .leading)
#endif
                }
            }
            
            // Editor
            TextField(placeholder, text: $field.onChange { value in
                fieldValidation = validate(value)
                fieldChanged(value)
            }).onAppear(perform: {
                fieldValidation = validate(field)
            }).focused(focus, equals: focusField)
#if os(iOS)
            .textInputAutocapitalization(.never)
#endif
        }
    }
}
