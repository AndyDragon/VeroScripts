//
//  TemplateEditorView.swift
//  Vero Scripts Editor
//
//  Created by Andrew Forget on 2024-12-29.
//

import SwiftUI
import SystemColors
import SwiftUIIntrospect

let staticPlaceholders = [
    "PAGENAME",
    "FULLPAGENAME",
    "PAGETITLE",
    "PAGEHASH",
    "USERNAME",
    "MEMBERLEVEL",
    "YOURNAME",
    "YOURFIRSTNAME",
    "STAFFLEVEL"
]
let allStaticPlaceholderPattern = "%%(.*?)%%"
let staticPlaceholderPattern = "%%(" + staticPlaceholders.joined(separator: "|") + ")%%"
let shortManualPlaceholderPattern = "\\[\\[(.*?)\\]\\]"
let longManualPlaceholderPattern = "\\[\\{(.*?)\\}\\]"

struct TemplateEditorView: View {
    @Bindable var viewModel: ContentView.ViewModel
    @Bindable var selectedTemplate: ObservableTemplate
    @State var focusedField: FocusState<FocusField?>.Binding
    @State private var manualPlaceholderKey = ""
    @State private var script = ""
    @State private var textView: NSTextView?
    @State private var attributedString: NSAttributedString
    @State private var isUpdating = false

    init(
        viewModel: ContentView.ViewModel,
        selectedTemplate: ObservableTemplate,
        focusedField: FocusState<FocusField?>.Binding
    ) {
        self.viewModel = viewModel
        self.selectedTemplate = selectedTemplate
        self.focusedField = focusedField
        self.attributedString = TemplateEditorView.updateAttributedString(selectedTemplate)
    }

    var body: some View {
        VStack {
            HStack {
                ForEach(staticPlaceholders, id: \.self) { placeholder in
                    Button(action: {
                        pasteTextToEditor("%%\(placeholder)%%")
                    }) {
                        Text(placeholder)
                    }
                }

                Text("|")
                    .padding(.horizontal)

                TextField(text: $manualPlaceholderKey) {
                    Text("Manual: ")
                }
                .frame(maxWidth: 80)

                Button(action: {
                    pasteTextToEditor("[[\(manualPlaceholderKey)]]")
                }) {
                    Text("Short")
                }
                .disabled(manualPlaceholderKey.isEmpty)

                Button(action: {
                    pasteTextToEditor("[{\(manualPlaceholderKey)}]")
                }) {
                    Text("Long")
                }
                .disabled(manualPlaceholderKey.isEmpty)

                Spacer()
            }

            TextEditor(text: $selectedTemplate.template)
                .font(.system(size: 12, design: .monospaced))
                .frame(minWidth: 200, maxWidth: .infinity, minHeight: 200, maxHeight: .infinity)
                .focusable()
                //.focused(focusedField, equals: .templateEditor)
                .padding(8)
                .background(Color.textBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .autocorrectionDisabled(false)
                .disableAutocorrection(false)
//                .introspect(.textEditor, on: .macOS(.v11, .v12, .v13, .v14, .v15)) { textView in
//                    self.textView = textView
//                }

            AttributedTextEditor(text: $attributedString.onChange { value in
                if !isUpdating {
                    isUpdating = true
                    print("Attributed string changed")
                    selectedTemplate.template = attributedString.string
                    updateScript()
                    isUpdating = false
                } else {
                    print("Attributed string change ignored")
                }
            }, foreground: Color.text, background: Color.textBackground)
                .frame(minWidth: 200, maxWidth: .infinity, minHeight: 200, maxHeight: .infinity)
                .focusable()
                .focused(focusedField, equals: .templateEditor)
                .padding(8)
                .background(Color.textBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .autocorrectionDisabled(false)
                .disableAutocorrection(false)
                .introspect(.textEditor, on: .macOS(.v11, .v12, .v13, .v14, .v15)) { textView in
                    self.textView = textView
                }

            Spacer()

            HStack {
                Text("User alias: ")
                TextField("", text: $viewModel.userAlias.onChange { value in
                    updateScript()
                })
                .focusable()

                Spacer()
                Text(" | ")
                Spacer()

                Picker("User level: ", selection: $viewModel.userLevel.onChange { value in
                    updateScript()
                }) {
                    ForEach(MembershipCase.casesFor(hub: viewModel.selectedPage!.hub)[1...]) { level in
                        Text(level.rawValue)
                            .tag(level)
                            .foregroundStyle(Color.TextColorSecondary, Color.TextColorSecondary)
                    }
                }
                .focusable()

                Spacer()
                Text(" | ")
                Spacer()

                Text("Your alias: ")
                TextField("", text: $viewModel.yourName.onChange { value in
                    updateScript()
                })
                .focusable()

                Spacer()
                Text(" | ")
                Spacer()

                Text("Your first name: ")
                TextField("Your first name", text: $viewModel.yourFirstName.onChange { value in
                    updateScript()
                })
                .focusable()

                Spacer()
                Text(" | ")
                Spacer()

                Picker("Your level: ", selection: $viewModel.pageStaffLevel.onChange { value in
                    updateScript()
                }) {
                    ForEach(StaffLevelCase.allCases) { staffLevelCase in
                        Text(staffLevelCase.rawValue)
                            .tag(staffLevelCase)
                            .foregroundStyle(Color.TextColorSecondary, Color.TextColorSecondary)
                    }
                }
                .focusable()

                Spacer()
            }

            Spacer()

            ScriptEditor(
                title: "Script:",
                script: $script,
                minHeight: 200,
                maxHeight: 640,
                canCopy: true,
                hasPlaceholders: false,
                copy: { _, _ in

                },
                focusedField: focusedField,
                editorFocusField: .scriptEditor,
                buttonFocusField: .scriptCopyButton
            )
        }
        .padding()
        .onAppear {
            updateScript()
        }
        .onChange(of: selectedTemplate) {
            if !isUpdating {
                print("Selected template changed")
                updateScript()
                attributedString = TemplateEditorView.updateAttributedString(selectedTemplate)
            } else {
                print("Selected template change ignored")
            }
        }
    }

    private func pasteTextToEditor(_ textToPaste: String) {
        if let textView {
            let nsTextView = (textView as NSTextView)
            if nsTextView.shouldChangeText(in: textView.selectedRange(), replacementString: textToPaste) {
                nsTextView.breakUndoCoalescing()
                nsTextView.undoManager?.beginUndoGrouping()
                nsTextView.textStorage?.beginEditing()
                nsTextView.textStorage?.replaceCharacters(in: textView.selectedRange(), with: textToPaste)
                nsTextView.textStorage?.endEditing()
                nsTextView.undoManager?.endUndoGrouping()
                nsTextView.breakUndoCoalescing()
            }
        }
    }

    private func updateScript() {
        let currentPageDisplayName = viewModel.selectedPage?.name ?? ""
        let scriptPageName = viewModel.selectedPage?.pageName ?? currentPageDisplayName
        let scriptPageHash = viewModel.selectedPage?.hashTag ?? currentPageDisplayName
        let scriptPageTitle = viewModel.selectedPage?.title ?? currentPageDisplayName
        script = selectedTemplate.template
            .replacingOccurrences(of: "%%PAGENAME%%", with: scriptPageName)
            .replacingOccurrences(of: "%%FULLPAGENAME%%", with: currentPageDisplayName)
            .replacingOccurrences(of: "%%PAGETITLE%%", with: scriptPageTitle)
            .replacingOccurrences(of: "%%PAGEHASH%%", with: scriptPageHash)
            .replacingOccurrences(of: "%%MEMBERLEVEL%%", with: viewModel.userLevel.rawValue)
            .replacingOccurrences(of: "%%USERNAME%%", with: viewModel.userAlias)
            .replacingOccurrences(of: "%%YOURNAME%%", with: viewModel.yourName)
            .replacingOccurrences(of: "%%YOURFIRSTNAME%%", with: viewModel.yourFirstName)
            .replacingOccurrences(of: "%%STAFFLEVEL%%", with: viewModel.pageStaffLevel.rawValue)
    }

    private static func updateAttributedString(_ selectedTemplate: ObservableTemplate) -> NSAttributedString {
        let mutableAttributedString = NSMutableAttributedString(string: selectedTemplate.template)
        let wholeRange = NSRange(selectedTemplate.template.startIndex..<selectedTemplate.template.endIndex, in: selectedTemplate.template)
        mutableAttributedString.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular), range: wholeRange)
        mutableAttributedString.addAttribute(.foregroundColor, value: NSColor(Color.text), range: wholeRange)
        let staticAllPlaceholders = selectedTemplate.template.enumeratePattern(using: allStaticPlaceholderPattern)
        for placeholder in staticAllPlaceholders {
            let nsRange = NSRange(placeholder, in: selectedTemplate.template)
            mutableAttributedString.addAttribute(.foregroundColor, value: NSColor(red: 1, green: 0, blue: 0, alpha: 1), range: nsRange)
        }
        let staticPlaceholders = selectedTemplate.template.enumeratePattern(using: staticPlaceholderPattern)
        for placeholder in staticPlaceholders {
            let nsRange = NSRange(placeholder, in: selectedTemplate.template)
            mutableAttributedString.addAttribute(.foregroundColor, value: NSColor(red: 1, green: 0, blue: 1, alpha: 1), range: nsRange)
        }
        let shortManualPlaceholders = selectedTemplate.template.enumeratePattern(using: shortManualPlaceholderPattern)
        for placeholder in shortManualPlaceholders {
            let nsRange = NSRange(placeholder, in: selectedTemplate.template)
            mutableAttributedString.addAttribute(.foregroundColor, value: NSColor(red: 0, green: 1, blue: 1, alpha: 1), range: nsRange)
        }
        let longManualPlaceholders = selectedTemplate.template.enumeratePattern(using: longManualPlaceholderPattern)
        for placeholder in longManualPlaceholders {
            let nsRange = NSRange(placeholder, in: selectedTemplate.template)
            mutableAttributedString.addAttribute(.foregroundColor, value: NSColor(red: 0, green: 1, blue: 0, alpha: 1), range: nsRange)
        }
        print("New state value")
        return mutableAttributedString
    }
}

struct AttributedTextEditor: NSViewRepresentable {
    @Binding var text: NSAttributedString
    var foreground: Color
    var background: Color

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else { fatalError() }
        context.coordinator.setTextView(textView)
        textView.delegate = context.coordinator
        textView.textColor = NSColor(foreground)
        textView.backgroundColor = NSColor(background)
        textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.allowsUndo = true
        textView.isAutomaticSpellingCorrectionEnabled = true
        //textView.dataSource = context.coordinator
        textView.delegate = context.coordinator
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let nsAttributedString = text
        guard let textView = scrollView.documentView as? NSTextView else { fatalError() }
        print("Update view")
        context.coordinator.setTextView(textView)
        textView.delegate = context.coordinator
        textView.backgroundColor = NSColor(background)
        textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.undoManager?.beginUndoGrouping()
        textView.textStorage?.beginEditing()
        textView.textStorage?.setAttributedString(nsAttributedString)
        textView.textStorage?.endEditing()
        textView.undoManager?.endUndoGrouping()
        textView.didChangeText()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self, $text)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: AttributedTextEditor
        var text: Binding<NSAttributedString>
        var textView: NSTextView? = nil

        init(_ parent: AttributedTextEditor, _ text: Binding<NSAttributedString>) {
            self.parent = parent
            self.text = text
        }

        func setTextView(_ textView: NSTextView) {
            self.textView = textView
        }

//        func textViewDidChange(_ textView: NSTextView) {
//            print(#function)
//            text.wrappedValue = textView.attributedString()
//        }

        func textDidChange(_ notification: Notification) {
            print(#function)
            if let textView {
                print("Setting text wrapped value")
                text.wrappedValue = textView.attributedString()
            }
        }

//        func textViewDidBeginEditing(_ textView: NSTextView) {
//            print(#function)
//            //parent.onEditingChanged?(true)
//        }
//
//        func textViewDidEndEditing(_ textView: NSTextView) {
//            print(#function)
//            //parent.onEditingCommit?()
//            //parent.onEditingChanged?(false)
//        }
    }
}
