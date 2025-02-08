//
//  DocumentDirtySheet.swift
//  Vero Scripts Editor
//
//  Created by Andrew Forget on 2024-11-23.
//

import SwiftUI
import UniformTypeIdentifiers

struct DocumentDirtySheet: View {
    @Binding var isShowing: Bool
    var confirmationText: String
    var dismissLabel: String
    var copyReportAction: () -> Void
    var saveReportAction: () -> Void
    var dismissAction: () -> Void
    var cancelAction: () -> Void

    var body: some View {
        VStack {
            HStack(alignment: .center) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.black, Color.yellow)
                    .font(.largeTitle)
                Spacer()
                    .frame(width: 16)
                Text("One or more templates have been edited")
                    .font(.title2)
                Spacer()
            }
            Spacer()
                .frame(height: 12)
            HStack {
                Spacer()
                    .frame(width: 50)
                Text(confirmationText)
                    .font(.title3)
                Spacer()
            }
            Spacer()
                .frame(height: 24)
            HStack(alignment: .bottom) {
                Spacer()
                Button(action: {
                    isShowing.toggle()
                    copyReportAction()
                }) {
                    Text("Copy report")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 4)
                }
                Spacer()
                Button(action: {
                    isShowing.toggle()
                    saveReportAction()
                }) {
                    Text("Save report")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 4)
                }
                Spacer()
                Button(action: {
                    isShowing.toggle()
                    cancelAction()
                }) {
                    Text("Cancel")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 4)
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                    .frame(width: 12)
                Button(action: {
                    isShowing.toggle()
                    dismissAction()
                }) {
                    Text(dismissLabel)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 4)
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .frame(width: 480)
        .padding(24)
    }
}
