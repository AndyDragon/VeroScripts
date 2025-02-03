//
//  SettingsView.swift
//  Vero Scripts Mobile
//
//  Created by Andrew Forget on 2025-02-03.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(
        "preference_includespace",
        store: UserDefaults(suiteName: "com.andydragon.com.Vero-Scripts-Mobile")
    ) var includeSpace = false

    var body: some View {
        VStack {
            Text("Settings")
                .font(.title)

            VStack(alignment: .leading, spacing: 0) {
                Section {
                    VStack(alignment: .leading, spacing: 0) {
                        Toggle(isOn: $includeSpace) {
                            Text("Insert a space after '@' in user tags when copying tags to the clipboard")
                        }
                        .tint(Color.accentColor)
                        .accentColor(Color.accentColor)

                        Text("For example, for the user tag '@alphabeta', the script will be '@ alphabeta'")
                            .padding(.top)
                            .font(.footnote)
                        Text("And for the page tag '@snap_longexposure', the script will be '@ snap_longexposure'")
                            .padding(.top)
                            .font(.footnote)
                    }
                } header: {
                    Text("Tags:")
                        .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                }
                .padding()
            }
            .background(Color.secondaryBackgroundColor.cornerRadius(8).opacity(0.4))
            .frame(maxWidth: .infinity)
            .padding()

            Spacer()

            VStack(alignment: .leading) {
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Close")
                            .padding([.leading, .trailing], 12)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .frame(maxWidth: .infinity)
            .padding([.leading, .top, .trailing])
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    SettingsView()
}
