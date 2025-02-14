//
//  FieldEditor.swift
//  Vero Scripts
//
//  Created by Andrew Forget on 2024-02-10.
//

import SwiftUI

struct FieldEditor: View {
    var title: String
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
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                // Title validator
                if fieldValidation.validation != .valid {
                    Image(systemName: fieldValidation.validation.icon)
                        .foregroundStyle(fieldValidation.validation.iconColor1, fieldValidation.validation.iconColor2)
                        .help(fieldValidation.reason ?? "")
                        .imageScale(.small)
                }

                // Title
                if !title.isEmpty {
                    Text(title)
                        .foregroundStyle(fieldValidation.validation.color, Color(UIColor.secondaryLabel))
                }
            }
            if fieldValidation.validation != .valid {
                Text(fieldValidation.reason ?? "")
                    .font(.footnote)
                    .foregroundStyle(fieldValidation.validation.color)
            }

            // Editor
            TextField(placeholder, text: $field.onChange { value in
                fieldValidation = validate(value)
                fieldChanged(value)
            }).onAppear(perform: {
                fieldValidation = validate(field)
            })
            .lineLimit(1)
            .foregroundStyle(Color(UIColor.label), Color(UIColor.secondaryLabel))
            .textFieldStyle(.plain)
            .padding(4)
            .background(Color.backgroundColor.opacity(0.5))
            .border(Color.gray.opacity(0.25))
            .cornerRadius(4)
            .frame(maxWidth: .infinity)
            .autocorrectionDisabled(true)
            .autocapitalization(.none)
        }
    }
}
