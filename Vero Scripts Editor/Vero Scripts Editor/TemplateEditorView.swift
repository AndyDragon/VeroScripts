//
//  TemplateEditorView.swift
//  Vero Scripts Editor
//
//  Created by Andrew Forget on 2024-12-29.
//

import SwiftUI
import SystemColors
import SwiftUIIntrospect
import SwiftyBeaver

struct TemplateEditorView: View {
    @Bindable var viewModel: ContentView.ViewModel
    @Bindable var selectedTemplate: ObservableTemplate
    @State var focusedField: FocusState<FocusField?>.Binding
    @State private var state = EditorState<ObservableTemplate>()
    @State private var manualPlaceholderKey = ""
    @State private var template = ""
    @State private var script = ""
    @State private var scriptPlaceholders = PlaceholderList()
    @State private var showingPlaceholderSheet = false
    let onDeleteTemplate: () -> Void

    private let logger = SwiftyBeaver.self

    var body: some View {
        VStack {
            HStack {
                Text("Template:")
                Spacer()
                Button(action: {
                    logger.verbose("Tapped copy template", context: "User")
                    Pasteboard.copyToClipboard(selectedTemplate.template)
                    viewModel.showSuccessToast("Copied", "Copied the script template to the clipboard")
                }) {
                    Text("Copy template")
                }
                Button(action: {
                    logger.verbose("Tapped paste template", context: "User")
                    state.resetText(Pasteboard.stringFromClipboard(), clearUndo: false)
                }) {
                    Text("Paste template")
                }
                .disabled(!Pasteboard.clipboardHasString)
                Button(action: {
                    logger.verbose("Tapped revert template", context: "User")
                    state.resetText(selectedTemplate.originalTemplate)
                }) {
                    Text("Revert template")
                }
                .disabled(!selectedTemplate.isDirty)
                Button(action: {
                    logger.verbose("Tapped remove template", context: "User")
                    onDeleteTemplate()
                }) {
                    Text("Remove template")
                }
            }

            HStack {
                Text("Insert:")
                    .lineLimit(1)
                ForEach(staticPlaceholders, id: \.self) { placeholder in
                    Button(action: {
                        logger.verbose("Tapped to insert placeholder", context: "User")
                        state.pasteTextToEditor("%%\(placeholder)%%")
                    }) {
                        Text("%%\(placeholder)%%")
                            .font(.system(size: 10))
                            .lineLimit(1)
                    }
                }
                Spacer()
            }

            HStack {
                Text("Insert:")
                    .lineLimit(1)
                    .opacity(0.000001)
                TextField(text: $manualPlaceholderKey) {
                    Text("Manual")
                        .lineLimit(1)
                }
                .frame(maxWidth: 120)
                Button(action: {
                    logger.verbose("Tapped to insert short manual placeholder", context: "User")
                    state.pasteTextToEditor("[[\(manualPlaceholderKey)]]")
                }) {
                    Text("Short")
                        .font(.system(size: 10))
                        .lineLimit(1)
                }
                .disabled(manualPlaceholderKey.isEmpty)
                Button(action: {
                    logger.verbose("Tapped to insert long manual placeholder", context: "User")
                    state.pasteTextToEditor("[{\(manualPlaceholderKey)}]")
                }) {
                    Text("Long")
                        .font(.system(size: 10))
                        .lineLimit(1)
                }
                .disabled(manualPlaceholderKey.isEmpty)
                Spacer()
            }

            TextEditor(text: $template)
                .font(.system(size: 14, design: .monospaced))
                .frame(minWidth: 200, maxWidth: .infinity, minHeight: 200, maxHeight: .infinity)
                .focusable()
                .focused(focusedField, equals: .templateEditor)
                .padding(8)
                .background(Color.textBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .autocorrectionDisabled(false)
                .disableAutocorrection(false)
                .introspect(.textEditor, on: .macOS(.v14, .v15)) { textView in
                    state.textView = textView
                    state.contextId = selectedTemplate.id
                    state.textView?.delegate = state
                    state.updateHighlighting()
                    state.onTextChanged = { value, contextId in
                        if contextId == selectedTemplate.id {
                            if selectedTemplate.template != value {
                                selectedTemplate.template = value
                                updateScript()
                            }
                        } else {
                            logger.error("ID mismatch caught in state.onTextChanged()", context: "System")
                        }
                    }
                }
                .introspect(.scrollView, on: .macOS(.v14, .v15)) { scrollView in
                    scrollView.scrollerStyle = .overlay
                    scrollView.autohidesScrollers = true
                    scrollView.scrollerStyle = .legacy
                }

            Divider()
                .padding(.vertical)

            HStack {
                Text("User alias: ")
                    .lineLimit(1)
                TextField("", text: $viewModel.userAlias.onChange { value in
                    updateScript()
                })
                .focusable()

                Text("|")
                    .padding(.horizontal)

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
                .lineLimit(1)

                Spacer()
            }

            HStack {
                Text("Your alias: ")
                    .lineLimit(1)
                TextField("", text: $viewModel.yourName.onChange { value in
                    updateScript()
                })
                .focusable()

                Text("|")
                    .padding(.horizontal)

                Text("Your first name: ")
                    .lineLimit(1)
                TextField("Your first name", text: $viewModel.yourFirstName.onChange { value in
                    updateScript()
                })
                .focusable()

                Text("|")
                    .padding(.horizontal)

                Picker("Your level: ", selection: $viewModel.pageStaffLevel.onChange { value in
                    updateScript()
                }) {
                    ForEach(StaffLevelCase.casesFor(hub: viewModel.selectedPage!.hub)) { staffLevelCase in
                        Text(staffLevelCase.rawValue)
                            .tag(staffLevelCase)
                            .foregroundStyle(Color.TextColorSecondary, Color.TextColorSecondary)
                    }
                }
                .focusable()
                .lineLimit(1)

                Spacer()
            }

            ScriptEditor(
                title: "Sample script:",
                isFeature: selectedTemplate.name == "feature",
                script: $script,
                minHeight: 200,
                maxHeight: 640,
                copy: {
                    if copyScript() {
                        logger.verbose("Copied the sample script", context: "User")
                        viewModel.showSuccessToast( "Copied", "Copied the sample script to the clipboard")
                    }
                },
                focusedField: focusedField,
                editorFocusField: .scriptEditor,
                buttonFocusField: .scriptCopyButton
            )
        }
        .sheet(isPresented: $showingPlaceholderSheet) {
            PlaceholderSheet(
                placeholders: scriptPlaceholders,
                script: script,
                closeSheetWithToast: { copiedSuffix in
                    let suffix = copiedSuffix.isEmpty ? "" : " \(copiedSuffix)"
                    viewModel.showSuccessToast("Copied", "Copied the script\(suffix) to the clipboard")
                    showingPlaceholderSheet.toggle()
                })
        }
        .padding()
        .onAppear {
            template = selectedTemplate.template
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.001,
                execute: {
                    state.updateHighlighting()
                })
            updateScript()
            scriptPlaceholders.placeholderDict.removeAll()
            scriptPlaceholders.longPlaceholderDict.removeAll()
        }
        .onChange(of: selectedTemplate) {
            template = selectedTemplate.template
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.001,
                execute: {
                    state.updateHighlighting()
                })
            updateScript()
            scriptPlaceholders.placeholderDict.removeAll()
            scriptPlaceholders.longPlaceholderDict.removeAll()
        }
    }

    private func updateScript() {
        let currentPageDisplayName = viewModel.selectedPage?.name ?? ""
        let scriptPageName = viewModel.selectedPage?.pageName ?? currentPageDisplayName
        let scriptPageHash = viewModel.selectedPage?.hashTag ?? currentPageDisplayName
        let scriptPageTitle = viewModel.selectedPage?.title ?? currentPageDisplayName
        let userLevelTitle = viewModel.userLevel.scriptMembershipStringForHub(hub: viewModel.selectedPage?.hub)
        script = selectedTemplate.template
            .replacingOccurrences(of: "%%PAGENAME%%", with: scriptPageName)
            .replacingOccurrences(of: "%%FULLPAGENAME%%", with: currentPageDisplayName)
            .replacingOccurrences(of: "%%PAGETITLE%%", with: scriptPageTitle)
            .replacingOccurrences(of: "%%PAGEHASH%%", with: scriptPageHash)
            .replacingOccurrences(of: "%%MEMBERLEVEL%%", with: userLevelTitle)
            .replacingOccurrences(of: "%%USERNAME%%", with: viewModel.userAlias)
            .replacingOccurrences(of: "%%YOURNAME%%", with: viewModel.yourName)
            .replacingOccurrences(of: "%%YOURFIRSTNAME%%", with: viewModel.yourFirstName)
            .replacingOccurrences(of: "%%STAFFLEVEL%%", with: viewModel.pageStaffLevel.rawValue)
    }

    private func scriptHasPlaceholders(_ script: String) -> Bool {
        return !matches(of: "\\[\\[([^\\]]*)\\]\\]", in: script).isEmpty || !matches(of: "\\[\\{([^\\}]*)\\}\\]", in: script).isEmpty
    }

    private func copyScript() -> Bool {
        if !checkForPlaceholders() {
            Pasteboard.copyToClipboard(script)
            return true
        }
        return false
    }

    private func checkForPlaceholders() -> Bool {
        var foundPlaceholders: [String] = [];
        foundPlaceholders.append(contentsOf: matches(of: "\\[\\[([^\\]]*)\\]\\]", in: script))
        if foundPlaceholders.count != 0 {
            for placeholder in foundPlaceholders {
                let placeholderEntry = scriptPlaceholders.placeholderDict[placeholder]
                if placeholderEntry == nil {
                    scriptPlaceholders.placeholderDict[placeholder] = PlaceholderValue()
                }
            }
        }
        var foundLongPlaceholders: [String] = [];
        foundLongPlaceholders.append(contentsOf: matches(of: "\\[\\{([^\\}]*)\\}\\]", in: script))
        if foundLongPlaceholders.count != 0 {
            for placeholder in foundLongPlaceholders {
                let placeholderEntry = scriptPlaceholders.longPlaceholderDict[placeholder]
                if placeholderEntry == nil {
                    scriptPlaceholders.longPlaceholderDict[placeholder] = PlaceholderValue()
                }
            }
        }
        if foundPlaceholders.count != 0 || foundLongPlaceholders.count != 0 && !showingPlaceholderSheet {
            logger.verbose("Script has manual placeholders, opening editor", context: "System")
            showingPlaceholderSheet.toggle()
            return true
        }
        return false
    }
}
