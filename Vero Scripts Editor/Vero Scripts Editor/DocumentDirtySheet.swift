//
//  DocumentDirtySheet.swift
//  Vero Scripts Editor
//
//  Created by Andrew Forget on 2024-11-23.
//

import AlertToast
import SwiftUI
import UniformTypeIdentifiers

struct DocumentDirtySheet: View {
    @Binding var isShowing: Bool
    @Binding var confirmationText: String
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
                    Text("Quit")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 4)
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .frame(width: 400)
        .padding(24)
    }
}
