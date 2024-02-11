//
//  PlaceholderEditor.swift
//  Vero Scripts
//
//  Created by Andrew Forget on 2024-02-10.
//

import SwiftUI

final class PlaceholderValue: ObservableObject {
    @Published var value = ""
}

final class PlaceholderList: ObservableObject {
    @Published var placeholderDict = [String: PlaceholderValue]()
}

struct PlaceholderView: View {
    let element: [String: PlaceholderValue].Element
    var editorName = ""
    @State var editorValue: String

    var body: some View {
        if #available(macOS 13.0, *) {
            HStack {
                Text(editorName.capitalized)
                    .frame(minWidth: 200)
                TextField(
                    "leave blank to remove placeholder",
                    text: $editorValue.onChange(editorValueChanged)
                )
                .frame(minWidth: 320)
                .padding(.all, 2)
#if os(iOS)
                .textInputAutocapitalization(.never)
#endif
                Spacer()
                    .background(Color.yellow)
            }
            .frame(maxWidth: .infinity)
#if !os(iOS)
            .textFieldStyle(.roundedBorder)
#endif
            .listRowSeparator(.hidden)
        } else {
            HStack {
                Text(element.key.capitalized)
                    .frame(minWidth: 200)
                TextField(
                    "leave blank to remove placeholder",
                    text: $editorValue.onChange(editorValueChanged)
                )
                .frame(minWidth: 320)
                .padding(.all, 2)
#if os(iOS)
                .textInputAutocapitalization(.never)
#endif
                Spacer()
                    .background(Color.yellow)
            }
            .frame(maxWidth: .infinity)
#if !os(iOS)
            .textFieldStyle(.roundedBorder)
#endif
        }
    }

    init(_ element: [String: PlaceholderValue].Element) {
        self.element = element
        let start = element.key.index(element.key.startIndex, offsetBy: 2)
        let end = element.key.index(element.key.endIndex, offsetBy: -3)
        editorName = String(element.key[start...end]);
        editorValue = element.value.value
    }

    func editorValueChanged(to: String) {
        element.value.value = editorValue
    }
}

struct PlaceholderSheet: View {
    @ObservedObject var placeholders: PlaceholderList
    @Binding var scriptWithPlaceholders: String
    @Binding var scriptWithPlaceholdersInPlace: String
    @Binding var isPresenting: Bool
    var transferPlaceholders: () -> Void
    
    var body: some View {
        ZStack {
            VStack {
                Text("There are manual placeholders that need to be filled out:")
                List() {
                    ForEach(placeholders.placeholderDict.sorted(by: { entry1, entry2 in entry1.key < entry2.key}), id: \.key) { entry in
                        PlaceholderView(entry)
#if os(iOS)
                            .padding(.horizontal, 20)
#endif
                    }
                }
                .listStyle(.plain)
                HStack {
                    Button(action: {
                        scriptWithPlaceholders = scriptWithPlaceholdersInPlace
                        placeholders.placeholderDict.forEach({ placeholder in
                            scriptWithPlaceholders = scriptWithPlaceholders.replacingOccurrences(of: placeholder.key, with: placeholder.value.value)
                        })
                        transferPlaceholders()
                        copyToClipboard(scriptWithPlaceholders)
                        isPresenting.toggle()
                    }, label: {
                        Text("Copy")
                            .padding(.horizontal, 20)
                    })
                    Button(action: {
                        copyToClipboard(scriptWithPlaceholdersInPlace)
                        isPresenting.toggle()
                    }, label: {
                        Text("Copy with Placeholders")
                            .padding(.horizontal, 20)
                    })
                }
            }
        }
        .frame(minWidth: 800, maxWidth: .infinity, minHeight: 600, maxHeight: .infinity)
        .padding()
    }
}
