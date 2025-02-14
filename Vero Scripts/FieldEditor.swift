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
    @Binding var fieldValidation: (validation: ValidationResult, reason: String?)
    var validate: (String) -> (validation: ValidationResult, reason: String?) = { value in
        if value.count == 0 {
            return (.error, "Required value")
        }
        return (.valid, nil)
    }
    var focus: FocusState<FocusedField?>.Binding
    var focusField: FocusedField
    
    var body: some View {
        HStack {
            // Title validator
            if fieldValidation.validation != .valid {
                Image(systemName: fieldValidation.validation.icon)
                    .foregroundStyle(fieldValidation.validation.iconColor1, fieldValidation.validation.iconColor2)
                    .help(fieldValidation.reason ?? "")
                    .imageScale(.small)
            }
            
            // Title
            if title.count != 0 {
                if titleWidth.isEmpty {
                    Text(title)
                        .foregroundStyle(fieldValidation.validation.color, Color.secondaryLabel)
                        .lineLimit(1)
                        .truncationMode(.tail)
                } else {
                    Text(title)
                        .foregroundStyle(fieldValidation.validation.color, Color.secondaryLabel)
                        .frame(width: titleWidth[0], alignment: .leading)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            
            // Editor
            TextField(placeholder, text: $field.onChange { value in
                fieldValidation = validate(value)
                fieldChanged(value)
            }).onAppear(perform: {
                fieldValidation = validate(field)
            })
            .focused(focus, equals: focusField)
            .lineLimit(1)
            .foregroundStyle(Color.label, Color.secondaryLabel)
            .textFieldStyle(.plain)
            .padding(4)
            .background(Color.controlBackground.opacity(0.5))
            .border(Color.gray.opacity(0.25))
            .cornerRadius(4)
        }
    }
}
