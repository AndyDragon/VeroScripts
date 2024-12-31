//
//  TemplateEditorView.swift
//  Vero Scripts Editor
//
//  Created by Andrew Forget on 2024-12-29.
//

import SwiftUI
import SystemColors
import SwiftUIIntrospect

struct TemplateEditorView: View {
    @Bindable var viewModel: ContentView.ViewModel
    @Bindable var selectedTemplate: ObservableTemplate
    @State var focusedField: FocusState<FocusField?>.Binding
    @State private var state = EditorState<ObservableTemplate>()
    @State private var manualPlaceholderKey = ""
    @State private var template = ""
    @State private var script = ""
    
    var body: some View {
        VStack {
            HStack {
                Text("Template:")
                Spacer()
            }
            HStack {
                Text("Insert placeholder:")
                ForEach(staticPlaceholders, id: \.self) { placeholder in
                    Button(action: {
                        state.pasteTextToEditor("%%\(placeholder)%%")
                    }) {
                        Text(placeholder)
                            .font(.system(size: 10))
                    }
                }
                
                Text("|")
                    .padding(.horizontal)
                
                TextField(text: $manualPlaceholderKey) {
                    Text("Manual: ")
                }
                .frame(maxWidth: 80)
                
                Button(action: {
                    state.pasteTextToEditor("[[\(manualPlaceholderKey)]]")
                }) {
                    Text("Short")
                        .font(.system(size: 10))
                }
                .disabled(manualPlaceholderKey.isEmpty)
                
                Button(action: {
                    state.pasteTextToEditor("[{\(manualPlaceholderKey)}]")
                }) {
                    Text("Long")
                        .font(.system(size: 10))
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
                            print("ID mismatch caught...")
                        }
                    }
                }
            
            Divider()
                .padding(.vertical)

            HStack {
                Text("User alias: ")
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
                
                Text("|")
                    .padding(.horizontal)
                
                Text("Your alias: ")
                TextField("", text: $viewModel.yourName.onChange { value in
                    updateScript()
                })
                .focusable()
                
                Text("|")
                    .padding(.horizontal)
                
                Text("Your first name: ")
                TextField("Your first name", text: $viewModel.yourFirstName.onChange { value in
                    updateScript()
                })
                .focusable()
                
                Text("|")
                    .padding(.horizontal)
                
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

            ScriptEditor(
                title: "Sample script:",
                script: $script,
                minHeight: 200,
                maxHeight: 640,
                focusedField: focusedField,
                editorFocusField: .scriptEditor,
                buttonFocusField: .scriptCopyButton
            )
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
        }
        .onChange(of: selectedTemplate) {
            template = selectedTemplate.template
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.001,
                execute: {
                    state.updateHighlighting()
                })
            updateScript()
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
}
