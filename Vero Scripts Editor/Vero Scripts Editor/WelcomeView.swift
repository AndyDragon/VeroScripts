//
//  WelcomeView.swift
//  Vero Scripts Editor
//
//  Created by Andrew Forget on 2024-12-29.
//

import SwiftUI

struct WelcomeView: View {
    var body: some View {
        Text("Welcome to Vero Scripts Editor")
            .font(.largeTitle)
        Text("Select a page on the left and then select a template to edit")
            .foregroundStyle(.secondary)
    }
}

#Preview {
    WelcomeView()
}
