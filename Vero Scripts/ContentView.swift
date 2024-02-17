//
//  ContentView.swift
//  Vero Scripts
//
//  Created by Andrew Forget on 2024-01-03.
//

import SwiftUI
import AlertToast

struct ContentView: View {
    @Environment(\.openURL) var openURL
    @State var membership: MembershipCase = MembershipCase.none
    @State var membershipValidation: (valid: Bool, reason: String?) = (true, nil)
    @State var userName: String = ""
    @State var userNameValidation: (valid: Bool, reason: String?) = (true, nil)
    @State var yourName: String = UserDefaults.standard.string(forKey: "YourName") ?? ""
    @State var yourNameValidation: (valid: Bool, reason: String?) = (true, nil)
    @State var yourFirstName: String = UserDefaults.standard.string(forKey: "YourFirstName") ?? ""
    @State var yourFirstNameValidation: (valid: Bool, reason: String?) = (true, nil)
    @State var page: String = UserDefaults.standard.string(forKey: "Page") ?? "default"
    @State var pageName: String = UserDefaults.standard.string(forKey: "PageName") ?? ""
    @State var pageValidation: (valid: Bool, reason: String?) = (true, nil)
    @State var pageStaffLevel: StaffLevelCase = StaffLevelCase(rawValue: UserDefaults.standard.string(forKey: "StaffLevel") ?? StaffLevelCase.mod.rawValue) ?? StaffLevelCase.mod
    @State var firstForPage: Bool = false
    @State var fromCommunityTag: Bool = false
    @State var featureScript: String = ""
    @State var commentScript: String = ""
    @State var originalPostScript: String = ""
    @State var newMembership: NewMembershipCase = NewMembershipCase.none
    @State var newMembershipScript: String = ""
    @State var showingAlert = false
    @State var alertTitle: String = ""
    @State var alertMessage: String = ""
    @State var terminalAlert = false
    @State var placeholderSheetCase = PlaceholderSheetCase.featureScript
    @State var showingPlaceholderSheet = false
    @State var pagesCatalog = PageCatalog(pages: [])
    @State var waitingForTemplates: Bool = true
    @State var templatesCatalog = TemplateCatalog(pages: [], specialTemplates: [])
    @State var disallowList = [String]()
    @ObservedObject var featureScriptPlaceholders = PlaceholderList()
    @ObservedObject var commentScriptPlaceholders = PlaceholderList()
    @ObservedObject var originalPostScriptPlaceholders = PlaceholderList()
    @State var scriptWithPlaceholdersInPlace = ""
    @State var scriptWithPlaceholders = ""
    @State var lastMembership = MembershipCase.none
    @State var lastUserName = ""
    @State var lastYourName = ""
    @State var lastYourFirstName = ""
    @State var lastPage = ""
    @State var lastPageName = ""
    @State var lastPageStaffLevel = StaffLevelCase.mod
    @State private var isShowingToast = false
    @State private var toastType = AlertToast.AlertType.regular
    @State private var toastDuration = 0.0
    @State private var toastText = ""
    @State private var toastSubTitle = ""
    @State private var toastTapAction: () -> Void = {}
    @FocusState var focusedField: FocusedField?
    var canCopyScripts: Bool {
        return membershipValidation.valid
        && userNameValidation.valid
        && yourNameValidation.valid
        && yourFirstNameValidation.valid
        && pageValidation.valid
    }
    var canCopyNewMembershipScript: Bool {
        return newMembership != NewMembershipCase.none
        && userNameValidation.valid
    }
    @Environment(\.colorScheme) var ColorScheme
    var appState: VersionCheckAppState
    private var isAnyToastShowing: Bool {
        isShowingToast || appState.isShowingVersionAvailableToast.wrappedValue || appState.isShowingVersionRequiredToast.wrappedValue
    }

    init(_ appState: VersionCheckAppState) {
        self.appState = appState
    }
    
    var body: some View {
        ZStack {
            VStack {
                Group {
                    HStack {
                        // User name editor
                        FieldEditor(
                            title: "User: ",
                            titleWidth: [42, 60],
                            placeholder: "Enter user name without '@'",
                            field: $userName,
                            fieldChanged: userNameChanged,
                            fieldValidation: $userNameValidation,
                            validate: validateUserName,
                            focus: $focusedField,
                            focusField: .userName
                        )
                        
                        // User level picker
                        if !membershipValidation.valid {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .help("Required value")
                                .imageScale(.small)
                                .padding([.leading], 8)
                        }
                        Text("Level: ")
                            .foregroundColor(.labelColor(membership != MembershipCase.none))
#if os(iOS)
                            .frame(width: 60, alignment: .leading)
#else
                            .frame(width: 36, alignment: .leading)
#endif
                            .padding([.leading], membership == MembershipCase.none ? 0 : 8)
                        Picker("", selection: $membership.onChange { value in
                            membershipValidation = validateMembership(value: value)
                            membershipChanged(to: value)
                        }) {
                            ForEach(MembershipCase.allCases) { level in
                                Text(level.rawValue).tag(level)
                            }
                        }
                        .onAppear {
                            membershipValidation = validateMembership(value: membership)
                        }
                        .focusable()
                        .focused($focusedField, equals: .level)
                        Spacer()
                    }
                    
                    HStack {
                        // Your name editor
                        FieldEditor(
                            title: "You:",
                            titleWidth: [42, 60],
                            placeholder: "Enter your user name without '@'",
                            field: $yourName,
                            fieldChanged: yourNameChanged,
                            fieldValidation: $yourNameValidation,
                            validate: { value in
                                if value.count == 0 {
                                    return (false, "Required value")
                                } else if value.first! == "@" {
                                    return (false, "Don't include the '@' in user names")
                                }
                                return (true, nil)
                            },
                            focus: $focusedField,
                            focusField: .yourName
                        )
                        
                        // Your first name editor
                        FieldEditor(
                            title: "Your first name:",
                            placeholder: "Enter your first name (capitalized)",
                            field: $yourFirstName,
                            fieldChanged: yourFirstNameChanged,
                            fieldValidation: $yourFirstNameValidation,
                            validate: { value in
                                if value.count == 0 {
                                    return (false, "Required value")
                                }
                                return (true, nil)
                            },
                            focus: $focusedField,
                            focusField: .yourFirstName
                        ).padding([.leading], 8)
                    }
                    
                    HStack {
                        // Page picker
                        if page == "default" && pageName.count == 0 {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .help("Page required")
                                .imageScale(.small)
                        }
                        Text("Page: ")
                            .foregroundColor(.labelColor(page != "default" || pageName.count != 0))
#if os(iOS)
                            .frame(width: 60, alignment: .leading)
#else
                            .frame(width: 36, alignment: .leading)
#endif
                        Picker("", selection: $page.onChange { value in
                            if page == "default" && pageName.count == 0 {
                                pageValidation = (false, "Page must not be 'default' or a page name is required")
                            } else {
                                pageValidation = (true, nil)
                            }
                            pageChanged(to: value)
                        }) {
                            ForEach(pagesCatalog.pages) { page in
                                Text(page.name).tag(page.name)
                            }
                        }
                        .focusable()
                        .focused($focusedField, equals: .page)
                        .onAppear {
                            if page == "default" && pageName.count == 0 {
                                pageValidation = (false, "Page must not be 'default' or a page name is required")
                            } else {
                                pageValidation = (true, nil)
                            }
                        }
                        
                        // Page name editor
                        TextField(
                            "Enter page name",
                            text: $pageName.onChange { value in
                                if page == "default" && pageName.count == 0 {
                                    pageValidation = (false, "Page must not be 'default' or a page name is required")
                                } else {
                                    pageValidation = (true, nil)
                                }
                                pageNameChanged(to: value)
                            }
                        )
                        .disabled(page != "default")
                        .focusable(page == "default")
                        .focused($focusedField, equals: .page)
#if os(iOS)
                        .textInputAutocapitalization(.never)
#endif
                        
                        // Page staff level picker
                        Text("Page staff level: ")
                            .padding([.leading], 8)
                        Picker("", selection: $pageStaffLevel.onChange(pageStaffLevelChanged)) {
                            ForEach(StaffLevelCase.allCases) { staffLevelCase in
                                Text(staffLevelCase.rawValue).tag(staffLevelCase)
                            }
                        }
                        .focusable()
                        .focused($focusedField, equals: .staffLevel)
                        
#if !os(iOS)
                        // Options
                        Toggle(isOn: $firstForPage.onChange(firstForPageChanged)) {
                            Text("First feature on page")
                        }
                        .focusable()
                        .focused($focusedField, equals: .firstFeature)
                        .padding([.leading], 8)
                        
                        Toggle(isOn: $fromCommunityTag.onChange(fromCommunityTagChanged)) {
                            Text("From community tag")
                        }
                        .focusable()
                        .focused($focusedField, equals: .communityTag)
                        .padding([.leading], 8)
#else
                        Spacer()
#endif
                    }
                }
                
#if os(iOS)
                HStack {
                    // Options
                    Toggle(isOn: $firstForPage.onChange(firstForPageChanged)) {
                        Text("First feature on page")
                    }
                    .focusable()
                    Toggle(isOn: $fromCommunityTag.onChange(fromCommunityTagChanged)) {
                        Text("From community tag")
                    }
                    .focusable()
                    Spacer()
                }
#endif
                
                Group {
                    // Feature script output
                    ScriptEditor(
                        title: "Feature script:",
                        script: $featureScript,
                        minHeight: 200,
                        maxHeight: .infinity,
                        canCopy: canCopyScripts,
                        hasPlaceholders: scriptHasPlaceholders(featureScript),
                        copy: { force, withPlaceholders in
                            placeholderSheetCase = .featureScript
                            if copyScript(
                                featureScript,
                                featureScriptPlaceholders,
                                [commentScriptPlaceholders, originalPostScriptPlaceholders],
                                force: force,
                                withPlaceholders: withPlaceholders) {
                                Task {
                                    await showToast(
                                        .complete(.green),
                                        "Copied",
                                        subTitle: "Copied the feature script\(withPlaceholders ? " with placeholders" : "") to the clipboard",
                                        duration: .short)
                                }
                            }
                        },
                        focus: $focusedField,
                        focusField: .featureScript)
                    
                    // Comment script output
                    ScriptEditor(
                        title: "Comment script:",
                        script: $commentScript,
                        minHeight: 80,
                        maxHeight: 160,
                        canCopy: canCopyScripts,
                        hasPlaceholders: scriptHasPlaceholders(commentScript),
                        copy: { force, withPlaceholders in
                            placeholderSheetCase = .commentScript
                            if copyScript(
                                commentScript,
                                commentScriptPlaceholders,
                                [featureScriptPlaceholders, originalPostScriptPlaceholders],
                                force: force,
                                withPlaceholders: withPlaceholders) {
                                Task {
                                    await showToast(
                                        .complete(.green),
                                        "Copied",
                                        subTitle: "Copied the comment script\(withPlaceholders ? " with placeholders" : "") to the clipboard",
                                        duration: .short)
                                }
                            }
                        },
                        focus: $focusedField,
                        focusField: .commentScript)
                    
                    // Original post script output
                    ScriptEditor(
                        title: "Original post script:",
                        script: $originalPostScript,
                        minHeight: 40,
                        maxHeight: 80,
                        canCopy: canCopyScripts,
                        hasPlaceholders: scriptHasPlaceholders(originalPostScript),
                        copy: { force, withPlaceholders in
                            placeholderSheetCase = .originalPostScript
                            if copyScript(
                                originalPostScript,
                                originalPostScriptPlaceholders,
                                [featureScriptPlaceholders, commentScriptPlaceholders],
                                force: force,
                                withPlaceholders: withPlaceholders) {
                                Task {
                                    await showToast(
                                        .complete(.green),
                                        "Copied",
                                        subTitle: "Copied the original script\(withPlaceholders ? " with placeholders" : "") to the clipboard",
                                        duration: .short)
                                }
                            }
                        },
                        focus: $focusedField,
                        focusField: .originalPostScript)
                }
                
                Group {
                    // New membership picker and script output
                    NewMembershipEditor(
                        newMembership: $newMembership,
                        script: $newMembershipScript,
                        onChanged: newMembershipChanged,
                        valid: userNameValidation.valid,
                        canCopy: canCopyNewMembershipScript,
                        copy: {
                            copyToClipboard(newMembershipScript)
                            Task {
                                await showToast(
                                    .complete(.green),
                                    "Copied",
                                    subTitle: "Copied the new membership script to the clipboard",
                                    duration: .short)
                            }
                        })
                }
            }
            .padding()
            .textFieldStyle(.roundedBorder)
            .alert(
                alertTitle,
                isPresented: $showingAlert,
                actions: {
                },
                message: {
                    Text(alertMessage)
                })
            .sheet(isPresented: $showingPlaceholderSheet) {
                PlaceholderSheet(
                    placeholders: placeholderSheetCase == .featureScript
                    ? featureScriptPlaceholders
                    : placeholderSheetCase == .commentScript
                    ? commentScriptPlaceholders
                    : originalPostScriptPlaceholders,
                    scriptWithPlaceholders: $scriptWithPlaceholders,
                    scriptWithPlaceholdersInPlace: $scriptWithPlaceholdersInPlace,
                    isPresenting: $showingPlaceholderSheet,
                    transferPlaceholders: {
                        switch placeholderSheetCase {
                        case .featureScript:
                            transferPlaceholderValues(
                                featureScriptPlaceholders,
                                [commentScriptPlaceholders, originalPostScriptPlaceholders])
                            break
                        case .commentScript:
                            transferPlaceholderValues(
                                commentScriptPlaceholders,
                                [featureScriptPlaceholders, originalPostScriptPlaceholders])
                            break
                        case .originalPostScript:
                            transferPlaceholderValues(
                                originalPostScriptPlaceholders,
                                [featureScriptPlaceholders, commentScriptPlaceholders])
                            break
                        }
                    },
                    toastCopyToClipboard: { copiedSuffix in
                        var scriptName: String
                        switch placeholderSheetCase {
                        case .featureScript:
                            scriptName = "feature"
                            break
                        case .commentScript:
                            scriptName = "comment"
                            break
                        case .originalPostScript:
                            scriptName = "original post"
                            break
                        }
                        let suffix = copiedSuffix.isEmpty ? "" : " \(copiedSuffix)"
                        Task {
                            await showToast(
                                .complete(.green),
                                "Copied",
                                subTitle: "Copied the \(scriptName) script\(suffix) to the clipboard",
                                duration: .short)
                        }
                    })
            }
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        userName = ""
                        userNameChanged(to: userName)
                        userNameValidation = validateUserName(value: userName)
                        membership = MembershipCase.none
                        membershipChanged(to: membership)
                        membershipValidation = validateMembership(value: membership)
                        firstForPage = false
                        firstForPageChanged(to: firstForPage)
                        fromCommunityTag = false
                        fromCommunityTagChanged(to: fromCommunityTag)
                        newMembership = NewMembershipCase.none
                        newMembershipChanged(to: newMembership)
                        focusedField = .userName
                    }) {
                        HStack {
                            Image(systemName: "xmark")
                                .foregroundStyle(.red)
                            Text("Clear user")
                                .font(.system(.body, design: .rounded).bold())
                                .foregroundColor(.red)
                        }
                        .padding(4)
                        .buttonStyle(.plain)
                    }.disabled(isAnyToastShowing)
                }
            }
            .allowsHitTesting(!isAnyToastShowing)
            if isAnyToastShowing {
                VStack {
                    Rectangle().opacity(0.0000001)
                }
                .onTapGesture {
                    if isShowingToast {
                        isShowingToast.toggle()
                    } else if appState.isShowingVersionAvailableToast.wrappedValue {
                        appState.isShowingVersionAvailableToast.wrappedValue.toggle()
                    }
                }
            }
        }
        .blur(radius: isAnyToastShowing ? 4 : 0)
        .toast(
            isPresenting: $isShowingToast,
            duration: 0,
            tapToDismiss: true,
            offsetY: 32,
            alert: {
                AlertToast(
                    displayMode: .hud,
                    type: toastType,
                    title: toastText,
                    subTitle: toastSubTitle)
            },
            onTap: toastTapAction,
            completion: {
                focusedField = .userName
            })
        .toast(
            isPresenting: appState.isShowingVersionAvailableToast,
            duration: 10,
            tapToDismiss: true,
            offsetY: 32,
            alert: {
                AlertToast(
                    displayMode: .hud,
                    type: .systemImage("exclamationmark.triangle.fill", .yellow),
                    title: "New version available",
                    subTitle: "You are using v\(appState.versionCheckToast.wrappedValue.appVersion) and v\(appState.versionCheckToast.wrappedValue.currentVersion) is available\(appState.versionCheckToast.wrappedValue.linkToCurrentVersion.isEmpty ? "" : ", click here to open your browser") (this will go away in 10 seconds)")
            },
            onTap: {
                if let url = URL(string: appState.versionCheckToast.wrappedValue.linkToCurrentVersion) {
                    openURL(url)
                }
            },
            completion: {
                appState.resetCheckingForUpdates()
                focusedField = .userName
            })
        .toast(
            isPresenting: appState.isShowingVersionRequiredToast,
            duration: 0,
            tapToDismiss: true,
            offsetY: 32,
            alert: {
                AlertToast(
                    displayMode: .hud,
                    type: .systemImage("xmark.octagon.fill", .red),
                    title: "New version required",
                    subTitle: "You are using v\(appState.versionCheckToast.wrappedValue.appVersion) and v\(appState.versionCheckToast.wrappedValue.currentVersion) is required\(appState.versionCheckToast.wrappedValue.linkToCurrentVersion.isEmpty ? "" : ", click here to open your browser") or ⌘ + Q to Quit")
            },
            onTap: {
                if let url = URL(string: appState.versionCheckToast.wrappedValue.linkToCurrentVersion) {
                    openURL(url)
                    NSApplication.shared.terminate(nil)
                }
            },
            completion: {
                appState.resetCheckingForUpdates()
                focusedField = .userName
            })        .onAppear {
            focusedField = .userName
        }
#if TESTING
        .navigationTitle("Vero Scripts - Script Testing")
#endif
        .task {
            // Hack for page staff level to handle changes (otherwise they are not persisted)
            lastPageStaffLevel = pageStaffLevel

            do {
#if TESTING
                let pagesUrl = URL(string: "https://vero.andydragon.com/static/data/testing/pages.json")!
#else
                let pagesUrl = URL(string: "https://vero.andydragon.com/static/data/pages.json")!
#endif
                pagesCatalog = try await URLSession.shared.decode(PageCatalog.self, from: pagesUrl)

                // Delay the start of the templates download so the window can be ready faster
                try await Task.sleep(nanoseconds: 1_000_000_000)

#if TESTING
                let templatesUrl = URL(string: "https://vero.andydragon.com/static/data/testing/templates.json")!
#else
                let templatesUrl = URL(string: "https://vero.andydragon.com/static/data/templates.json")!
#endif
                templatesCatalog = try await URLSession.shared.decode(TemplateCatalog.self, from: templatesUrl)
                waitingForTemplates = false
                updateScripts()
                updateNewMembershipScripts()

                do {
                    // Delay the start of the disallowed list download so the window can be ready faster
                    try await Task.sleep(nanoseconds: 1_000_000_000)

#if TESTING
                    let disallowListUrl = URL(string: "https://vero.andydragon.com/static/data/testing/disallowlist.json")!
#else
                    let disallowListUrl = URL(string: "https://vero.andydragon.com/static/data/disallowlist.json")!
#endif
                    disallowList = try await URLSession.shared.decode([String].self, from: disallowListUrl)
                    updateScripts()
                    updateNewMembershipScripts()
                } catch {
                    // do nothing, the disallow list is not critical
                    debugPrint(error.localizedDescription)
                }

                do {
                    // Delay the start of the disallowed list download so the window can be ready faster
                    try await Task.sleep(nanoseconds: 100_000_000)

                    appState.checkForUpdates()
                } catch {
                    // do nothing, the version check is not critical
                    debugPrint(error.localizedDescription)
                }
            } catch {
                alertTitle = "Could not load the page catalog from the server"
                alertMessage = "The application requires the catalog to perform its operations: " + error.localizedDescription
                terminalAlert = true
                showingAlert = true
            }
        }
    }
    
    func showToast(
        _ type: AlertToast.AlertType,
        _ text: String,
        subTitle: String = "",
        duration: ToastDuration,
        onTap: @escaping () -> Void = {}
    ) async {
        toastType = type
        toastText = text
        toastSubTitle = subTitle
        toastTapAction = onTap
        isShowingToast.toggle()

        if duration != .disabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(duration.rawValue), execute: {
                if (isShowingToast) {
                    isShowingToast.toggle()
                }
            })
        }
    }

    func membershipChanged(to value: MembershipCase) {
        if value != lastMembership {
            featureScriptPlaceholders.placeholderDict.removeAll()
            commentScriptPlaceholders.placeholderDict.removeAll()
            originalPostScriptPlaceholders.placeholderDict.removeAll()
            updateScripts()
            lastMembership = value
        }
    }
    
    func validateMembership(value: MembershipCase) -> (valid: Bool, reason: String?) {
        if value == MembershipCase.none {
            return (false, "Required value")
        }
        return (true, nil)
    }

    func userNameChanged(to value: String) {
        if value != lastUserName {
            featureScriptPlaceholders.placeholderDict.removeAll()
            commentScriptPlaceholders.placeholderDict.removeAll()
            originalPostScriptPlaceholders.placeholderDict.removeAll()
            updateScripts()
            updateNewMembershipScripts()
            lastUserName = value
        }
    }
    
    func validateUserName(value: String) -> (valid: Bool, reason: String?) {
        if value.count == 0 {
            return (false, "Required value")
        } else if value.first! == "@" {
            return (false, "Don't include the '@' in user names")
        } else if (disallowList.first { disallow in disallow == value } != nil) {
            return (false, "User is on the disallow list")
        }
        return (true, nil)
    }

    func yourNameChanged(to value: String) {
        if value != lastYourName {
            featureScriptPlaceholders.placeholderDict.removeAll()
            commentScriptPlaceholders.placeholderDict.removeAll()
            originalPostScriptPlaceholders.placeholderDict.removeAll()
            UserDefaults.standard.set(yourName, forKey: "YourName")
            updateScripts()
            updateNewMembershipScripts()
            lastYourName = value
        }
    }

    func yourFirstNameChanged(to value: String) {
        if value != lastYourFirstName {
            featureScriptPlaceholders.placeholderDict.removeAll()
            commentScriptPlaceholders.placeholderDict.removeAll()
            originalPostScriptPlaceholders.placeholderDict.removeAll()
            UserDefaults.standard.set(yourFirstName, forKey: "YourFirstName")
            updateScripts()
            updateNewMembershipScripts()
            lastYourFirstName = value
        }
    }

    func pageChanged(to value: String) {
        if value != lastPage {
            featureScriptPlaceholders.placeholderDict.removeAll()
            commentScriptPlaceholders.placeholderDict.removeAll()
            originalPostScriptPlaceholders.placeholderDict.removeAll()
            UserDefaults.standard.set(page, forKey: "Page")
            updateScripts()
            lastPage = value
        }
    }

    func pageNameChanged(to value: String) {
        if value != lastPageName {
            featureScriptPlaceholders.placeholderDict.removeAll()
            commentScriptPlaceholders.placeholderDict.removeAll()
            originalPostScriptPlaceholders.placeholderDict.removeAll()
            UserDefaults.standard.set(pageName, forKey: "PageName")
            updateScripts()
            lastPageName = value
        }
    }

    func pageStaffLevelChanged(to value: StaffLevelCase) {
        if value != lastPageStaffLevel {
            featureScriptPlaceholders.placeholderDict.removeAll()
            commentScriptPlaceholders.placeholderDict.removeAll()
            originalPostScriptPlaceholders.placeholderDict.removeAll()
            UserDefaults.standard.set(pageStaffLevel.rawValue, forKey: "StaffLevel")
            updateScripts()
            lastPageStaffLevel = value
        }
    }

    func firstForPageChanged(to value: Bool) {
        updateScripts()
    }

    func fromCommunityTagChanged(to value: Bool) {
        updateScripts()
    }

    func newMembershipChanged(to value: NewMembershipCase) {
        updateNewMembershipScripts()
    }

    func copyScript(_ script: String, _ placeholders: PlaceholderList, _ otherPlaceholders: [PlaceholderList], force: Bool = false, withPlaceholders: Bool = false) -> Bool {
        scriptWithPlaceholders = script
        scriptWithPlaceholdersInPlace = script
        placeholders.placeholderDict.forEach({ placeholder in
            scriptWithPlaceholders = scriptWithPlaceholders.replacingOccurrences(of: placeholder.key, with: placeholder.value.value)
        })
        if withPlaceholders {
            copyToClipboard(scriptWithPlaceholdersInPlace)
            return true
        } else if !checkForPlaceholders(scriptWithPlaceholdersInPlace, placeholders, otherPlaceholders, force: force) {
            copyToClipboard(scriptWithPlaceholders)
            return true
        }
        return false
    }
    
    func transferPlaceholderValues(_ scriptPlaceholders: PlaceholderList, _ otherPlaceholders: [PlaceholderList]) -> Void {
        scriptPlaceholders.placeholderDict.forEach { placeholder in
            otherPlaceholders.forEach { destinationPlaceholders in
                let destinationPlaceholderEntry = destinationPlaceholders.placeholderDict[placeholder.key]
                if destinationPlaceholderEntry != nil {
                    destinationPlaceholderEntry!.value = placeholder.value.value
                }
            }
        }
    }

    func scriptHasPlaceholders(_ script: String) -> Bool {
        return !matches(of: "\\[\\[([^\\]]*)\\]\\]", in: script).isEmpty
    }
    
    func checkForPlaceholders(_ script: String, _ placeholders: PlaceholderList, _ otherPlaceholders: [PlaceholderList], force: Bool = false) -> Bool {
        var foundPlaceholders: [String] = [];
        foundPlaceholders.append(contentsOf: matches(of: "\\[\\[([^\\]]*)\\]\\]", in: script))
        if foundPlaceholders.count != 0 {
            var needEditor: Bool = false
            for placeholder in foundPlaceholders {
                let placeholderEntry = placeholders.placeholderDict[placeholder]
                if placeholderEntry == nil {
                    needEditor = true
                    var value: String? = nil
                    otherPlaceholders.forEach { sourcePlaceholders in
                        let sourcePlaceholderEntry = sourcePlaceholders.placeholderDict[placeholder]
                        if (value == nil || value!.isEmpty) && sourcePlaceholderEntry != nil && !(sourcePlaceholderEntry?.value ?? "").isEmpty {
                            value = sourcePlaceholderEntry?.value
                        }
                    }
                    placeholders.placeholderDict[placeholder] = PlaceholderValue()
                    if value != nil {
                        placeholders.placeholderDict[placeholder]?.value = value!
                    }
                }
            }
            if (force || needEditor) && !showingPlaceholderSheet {
                showingPlaceholderSheet.toggle()
                return true
            }
        }
        return false
    }
    
    func updateScripts() -> Void {
        if !canCopyScripts {
            var validationErrors = ""
            if !userNameValidation.valid {
                validationErrors += "User: " + userNameValidation.reason! + "\n"
            }
            if !membershipValidation.valid {
                validationErrors += "Level: " + membershipValidation.reason! + "\n"
            }
            if !yourNameValidation.valid {
                validationErrors += "You: " + yourNameValidation.reason! + "\n"
            }
            if !yourFirstNameValidation.valid {
                validationErrors += "Your first name: " + yourFirstNameValidation.reason! + "\n"
            }
            if !pageValidation.valid {
                validationErrors += "Page: " + pageValidation.reason! + "\n"
            }
            featureScript = validationErrors
            originalPostScript = ""
            commentScript = ""
        } else {
            let currentPageName = page == "default" ? pageName : page
            var scriptPageName = currentPageName
            if currentPageName != "default" {
                let pageSource = pagesCatalog.pages.first(where: { needle in needle.name == page })
                if pageSource != nil && pageSource?.pageName != nil {
                    scriptPageName = (pageSource?.pageName)!
                }
            }
            let featureScriptTemplate = getTemplateFromCatalog(
                "feature",
                from: currentPageName,
                firstFeature: firstForPage,
                communityTag: fromCommunityTag) ?? ""
            let commentScriptTemplate = getTemplateFromCatalog(
                "comment",
                from: currentPageName,
                firstFeature: firstForPage,
                communityTag: fromCommunityTag) ?? ""
            let originalPostScriptTemplate = getTemplateFromCatalog(
                "original post",
                from: currentPageName,
                firstFeature: firstForPage,
                communityTag: fromCommunityTag) ?? ""
            featureScript = featureScriptTemplate
                .replacingOccurrences(of: "%%PAGENAME%%", with: scriptPageName)
                .replacingOccurrences(of: "%%FULLPAGENAME%%", with: currentPageName)
                .replacingOccurrences(of: "%%MEMBERLEVEL%%", with: membership.rawValue)
                .replacingOccurrences(of: "%%USERNAME%%", with: userName)
                .replacingOccurrences(of: "%%YOURNAME%%", with: yourName)
                .replacingOccurrences(of: "%%YOURFIRSTNAME%%", with: yourFirstName)
                // Special case for 'YOUR FIRST NAME' since it's now autofilled.
                .replacingOccurrences(of: "[[YOUR FIRST NAME]]", with: yourFirstName)
                .replacingOccurrences(of: "%%STAFFLEVEL%%", with: pageStaffLevel.rawValue)
            originalPostScript = originalPostScriptTemplate
                .replacingOccurrences(of: "%%PAGENAME%%", with: scriptPageName)
                .replacingOccurrences(of: "%%FULLPAGENAME%%", with: currentPageName)
                .replacingOccurrences(of: "%%MEMBERLEVEL%%", with: membership.rawValue)
                .replacingOccurrences(of: "%%USERNAME%%", with: userName)
                .replacingOccurrences(of: "%%YOURNAME%%", with: yourName)
                .replacingOccurrences(of: "%%YOURFIRSTNAME%%", with: yourFirstName)
                // Special case for 'YOUR FIRST NAME' since it's now autofilled.
                .replacingOccurrences(of: "[[YOUR FIRST NAME]]", with: yourFirstName)
                .replacingOccurrences(of: "%%STAFFLEVEL%%", with: pageStaffLevel.rawValue)
            commentScript = commentScriptTemplate
                .replacingOccurrences(of: "%%PAGENAME%%", with: scriptPageName)
                .replacingOccurrences(of: "%%FULLPAGENAME%%", with: currentPageName)
                .replacingOccurrences(of: "%%MEMBERLEVEL%%", with: membership.rawValue)
                .replacingOccurrences(of: "%%USERNAME%%", with: userName)
                .replacingOccurrences(of: "%%YOURNAME%%", with: yourName)
                .replacingOccurrences(of: "%%YOURFIRSTNAME%%", with: yourFirstName)
                // Special case for 'YOUR FIRST NAME' since it's now autofilled.
                .replacingOccurrences(of: "[[YOUR FIRST NAME]]", with: yourFirstName)
                .replacingOccurrences(of: "%%STAFFLEVEL%%", with: pageStaffLevel.rawValue)
        }
    }

    func getTemplateFromCatalog(_ templateName: String, from pageName: String, firstFeature: Bool, communityTag: Bool) -> String! {
        var template: Template!
        if waitingForTemplates {
            return "";
        }
        let defaultTemplatePage = templatesCatalog.pages.first(where: { page in page.name == "default" });
        let templatePage = templatesCatalog.pages.first(where: { page in page.name == pageName});
        if communityTag {
            template = templatePage?.templates.first(where: { template in template.name == "community " + templateName })
            if template == nil {
                template = defaultTemplatePage?.templates.first(where: { template in template.name == "community " + templateName })
            }
        } else if firstFeature {
            template = templatePage?.templates.first(where: { template in template.name == "first " + templateName })
            if template == nil {
                template = defaultTemplatePage?.templates.first(where: { template in template.name == "first " + templateName })
            }
        }
        if template == nil {
            template = templatePage?.templates.first(where: { template in template.name == templateName })
        }
        if template == nil {
            template = defaultTemplatePage?.templates.first(where: { template in template.name == templateName })
        }
        return template?.template
    }

    func updateNewMembershipScripts() -> Void {
        if waitingForTemplates {
            newMembershipScript = ""
            return
        }
        if !canCopyNewMembershipScript {
            var validationErrors = ""
            if !userNameValidation.valid {
                validationErrors += "User: " + userNameValidation.reason! + "\n"
            }
            newMembershipScript = validationErrors
        } else if newMembership == NewMembershipCase.member {
            let template = templatesCatalog.specialTemplates.first(where: { template in template.name == "new member" })
            if template == nil {
                newMembershipScript = ""
                return
            }
            newMembershipScript = template!.template
                .replacingOccurrences(of: "%%USERNAME%%", with: userName)
                .replacingOccurrences(of: "%%YOURNAME%%", with: yourName)
                .replacingOccurrences(of: "%%YOURFIRSTNAME%%", with: yourFirstName)
        } else if newMembership == NewMembershipCase.vipMember {
            let template = templatesCatalog.specialTemplates.first(where: { template in template.name == "new vip member" })
            if template == nil {
                newMembershipScript = ""
                return
            }
            newMembershipScript = template!.template
                .replacingOccurrences(of: "%%USERNAME%%", with: userName)
                .replacingOccurrences(of: "%%YOURNAME%%", with: yourName)
                .replacingOccurrences(of: "%%YOURFIRSTNAME%%", with: yourFirstName)
        }
    }
}
