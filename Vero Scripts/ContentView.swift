//
//  ContentView.swift
//  Vero Scripts
//
//  Created by Andrew Forget on 2024-01-03.
//

import SwiftUI
import CloudKit

import AlertToast

var ThemeDetails: [Theme:(colorTheme:String,darkTheme:Bool)] = [
    Theme.systemDark: (colorTheme: "", darkTheme: true),
    Theme.darkSubtleGray: (colorTheme: "SubtleGray", darkTheme: true),
    Theme.darkBlue: (colorTheme: "Blue", darkTheme: true),
    Theme.darkGreen: (colorTheme: "Green", darkTheme: true),
    Theme.darkRed: (colorTheme: "Red", darkTheme: true),
    Theme.darkViolet: (colorTheme: "Violet", darkTheme: true),
    Theme.systemLight: (colorTheme: "", darkTheme: false),
    Theme.lightSubtleGray: (colorTheme: "SubtleGray", darkTheme: false),
    Theme.lightBlue: (colorTheme: "Blue", darkTheme: false),
    Theme.lightGreen: (colorTheme: "Green", darkTheme: false),
    Theme.lightRed: (colorTheme: "Red", darkTheme: false),
    Theme.lightViolet: (colorTheme: "Violet", darkTheme: false)
]

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    @Environment(\.openURL) var openURL
    @State var membership: MembershipCase = MembershipCase.none
    @State var membershipValidation: (valid: Bool, reason: String?) = (true, nil)
    @State var userName: String = ""
    @State var userNameValidation: (valid: Bool, reason: String?) = (true, nil)
    @State var yourName: String = UserDefaults.standard.string(forKey: "YourName") ?? ""
    @State var yourNameValidation: (valid: Bool, reason: String?) = (true, nil)
    @State var yourFirstName: String = UserDefaults.standard.string(forKey: "YourFirstName") ?? ""
    @State var yourFirstNameValidation: (valid: Bool, reason: String?) = (true, nil)
    @State var page: String = UserDefaults.standard.string(forKey: "Page") ?? ""
    @State var pageValidation: (valid: Bool, reason: String?) = (true, nil)
    @State var pageStaffLevel: StaffLevelCase = StaffLevelCase(
        rawValue: UserDefaults.standard.string(forKey: "StaffLevel") ?? StaffLevelCase.mod.rawValue
    ) ?? StaffLevelCase.mod
    @State var firstForPage: Bool = false
    @State var fromCommunityTag: Bool = false
    @State var fromRawTag: Bool = false
    @State var featureScript: String = ""
    @State var commentScript: String = ""
    @State var originalPostScript: String = ""
    @State var newMembership: NewMembershipCase = NewMembershipCase.none
    @State var newMembershipValidation: (valid: Bool, reason: String?) = (true, nil)
    @State var newMembershipScript: String = ""
    @State var showingAlert = false
    @State var alertTitle: String = ""
    @State var alertMessage: String = ""
    @State var terminalAlert = false
    @State var placeholderSheetCase = PlaceholderSheetCase.featureScript
    @State var showingPlaceholderSheet = false
    @State var loadedPages = [LoadedPage]()
    @State var currentPage: LoadedPage? = nil
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
    @State var lastPageStaffLevel = StaffLevelCase.mod
    @State private var isShowingToast = false
    @State private var toastType = AlertToast.AlertType.regular
    @State private var toastDuration = 0.0
    @State private var toastText = ""
    @State private var toastSubTitle = ""
    @State private var toastTapAction: () -> Void = {}
    @FocusState var focusedField: FocusedField?
    @State private var theme = Theme.notSet
    @State private var isDarkModeOn = true
    var canCopyScripts: Bool {
        return membershipValidation.valid
        && userNameValidation.valid
        && yourNameValidation.valid
        && yourFirstNameValidation.valid
        && pageValidation.valid
    }
    var canCopyNewMembershipScript: Bool {
        return newMembership != NewMembershipCase.none
        && newMembershipValidation.valid
        && userNameValidation.valid
    }
    @Environment(\.colorScheme) var ColorScheme
    var appState: VersionCheckAppState
    private var isAnyToastShowing: Bool {
        isShowingToast
        || appState.isShowingVersionAvailableToast.wrappedValue
        || appState.isShowingVersionRequiredToast.wrappedValue
    }
    private var accordionHeightRatio = 3.5

    init(_ appState: VersionCheckAppState) {
        self.appState = appState
    }

    var body: some View {
        ZStack {
            Color.BackgroundColor.edgesIgnoringSafeArea(.all)
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
                                .foregroundStyle(Color.AccentColor, Color.TextColorRequired)
                                .help(membershipValidation.reason ?? "unknown error")
                                .imageScale(.small)
                                .padding([.leading], 8)
                        }
                        Text("Level: ")
                            .foregroundStyle(
                                membershipValidation.valid ? Color.TextColorPrimary : Color.TextColorRequired,
                                Color.TextColorSecondary)
#if os(iOS)
                            .frame(width: 60, alignment: .leading)
#else
                            .frame(width: 36, alignment: .leading)
#endif
                            .padding([.leading], membershipValidation.valid ? 8 : 0)
                        Picker("", selection: $membership.onChange { value in
                            membershipValidation = validateMembership(value: membership)
                            membershipChanged(to: value)
                        }) {
                            ForEach(MembershipCase.casesFor(hub: currentPage?.hub)) { level in
                                Text(level.rawValue)
                                    .tag(level)
                                    .foregroundStyle(Color.TextColorSecondary, Color.TextColorSecondary)
                            }
                        }
                        .tint(Color.AccentColor)
                        .accentColor(Color.AccentColor)
#if os(iOS)
                        .frame(minWidth: 120, alignment: .leading)
#endif
                        .onAppear {
                            membershipValidation = validateMembership(value: membership)
                        }
                        .focusable()
                        .focused($focusedField, equals: .level)
#if os(iOS)
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
                            fromRawTag = false
                            fromRawTagChanged(to: fromRawTag)
                            newMembership = NewMembershipCase.none
                            newMembershipChanged(to: newMembership)
                            newMembershipValidation = validateNewMembership(value: newMembership)
                            focusedField = .userName
                        }) {
                            HStack {
                                Image(systemName: "xmark")
                                    .foregroundStyle(Color.TextColorRequired, Color.TextColorSecondary)
                                Text("Clear user")
                                    .font(.system(.body, design: .rounded).bold())
                                    .foregroundStyle(Color.TextColorRequired, Color.TextColorSecondary)
                            }
                            .padding(4)
                            .buttonStyle(.plain)
                        }.disabled(isAnyToastShowing)
#endif
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
                        if !pageValidation.valid {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color.AccentColor, Color.TextColorRequired)
                                .help(pageValidation.reason ?? "unknown error")
                                .imageScale(.small)
                        }
                        Text("Page: ")
                            .foregroundStyle(
                                pageValidation.valid ? Color.TextColorPrimary : Color.TextColorRequired,
                                Color.TextColorSecondary)
#if os(iOS)
                            .frame(width: 60, alignment: .leading)
#else
                            .frame(width: 36, alignment: .leading)
#endif
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Picker("", selection: $page.onChange { value in
                            if page.isEmpty {
                                pageValidation = (false, "Page is required")
                            } else {
                                pageValidation = (true, nil)
                            }
                            pageChanged(to: value)
                        }) {
                            ForEach(loadedPages) { page in
                                Text(page.displayName)
                                    .tag(page.id)
                                    .foregroundStyle(Color.TextColorSecondary, Color.TextColorSecondary)
                            }
                        }
                        .tint(Color.AccentColor)
                        .accentColor(Color.AccentColor)
                        .focusable()
                        .focused($focusedField, equals: .page)
#if os(iOS)
                        .frame(minWidth: 120, alignment: .leading)
#endif
                        .onAppear {
                            if page.isEmpty {
                                pageValidation = (false, "Page must not be 'default' or a page name is required")
                            } else {
                                pageValidation = (true, nil)
                            }
                        }

                        // Page staff level picker
                        Text("Page staff level: ")
                            .padding([.leading], 8)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Picker("", selection: $pageStaffLevel.onChange(pageStaffLevelChanged)) {
                            ForEach(StaffLevelCase.allCases) { staffLevelCase in
                                Text(staffLevelCase.rawValue)
                                    .tag(staffLevelCase)
                                    .foregroundStyle(Color.TextColorSecondary, Color.TextColorSecondary)
                            }
                        }
                        .tint(Color.AccentColor)
                        .accentColor(Color.AccentColor)
                        .focusable()
                        .focused($focusedField, equals: .staffLevel)
#if os(iOS)
                        .frame(minWidth: 120, alignment: .leading)
#endif

#if !os(iOS)
                        // Options
                        Toggle(isOn: $firstForPage.onChange(firstForPageChanged)) {
                            Text("First feature on page")
                            .lineLimit(1)
                            .truncationMode(.tail)
                        }
                        .focusable()
                        .focused($focusedField, equals: .firstFeature)
                        .padding([.leading], 8)
                        .help("First feature on page")

                        if currentPage?.hub == "snap" {
                            Toggle(isOn: $fromRawTag.onChange(fromRawTagChanged)) {
                                Text("From RAW tag")
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                            .focusable()
                            .focused($focusedField, equals: .rawTag)
                            .padding([.leading], 8)
                            .help("From RAW tag")

                            Toggle(isOn: $fromCommunityTag.onChange(fromCommunityTagChanged)) {
                                Text("From community tag")
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                            .focusable()
                            .focused($focusedField, equals: .communityTag)
                            .padding([.leading], 8)
                            .help("From community tag")
                        }
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
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .focusable()
                    Spacer()
                        .frame(width: 20)
                    Rectangle()
                        .frame(width: 1, height: 24)
                        .background(Color.gray)
                        .opacity(0.2)
                    Spacer()
                        .frame(width: 20)
                    Toggle(isOn: $fromRawTag.onChange(fromRawTagChanged)) {
                        Text("From RAW tag")
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .focusable()
                    Spacer()
                        .frame(width: 20)
                    Rectangle()
                        .frame(width: 1, height: 24)
                        .background(Color.gray)
                        .opacity(0.2)
                    Spacer()
                        .frame(width: 20)
                    Toggle(isOn: $fromCommunityTag.onChange(fromCommunityTagChanged)) {
                        Text("From community tag")
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .focusable()
                }
#endif

                Group {
                    // Feature script output
                    ScriptEditor(
                        title: "Feature script:",
                        script: $featureScript,
                        minHeight: 72,
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
                                        subTitle: String {
                                            "Copied the feature script\(withPlaceholders ? " with placeholders" : "") "
                                            "to the clipboard"
                                        },
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
                        minHeight: 36,
                        maxHeight: 36 * accordionHeightRatio,
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
                                        subTitle: String {
                                            "Copied the comment script\(withPlaceholders ? " with placeholders" : "") "
                                            "to the clipboard"
                                        },
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
                        minHeight: 24,
                        maxHeight: 24 * accordionHeightRatio,
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
                                        subTitle: String {
                                            "Copied the original script\(withPlaceholders ? " with placeholders" : "") "
                                            "to the clipboard"
                                        },
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
                        currentPage: $currentPage,
                        minHeight: 36,
                        maxHeight: 36 * accordionHeightRatio,
                        onChanged: { newValue in
                            newMembershipValidation = validateNewMembership(value: newMembership)
                            newMembershipChanged(to: newValue)
                        },
                        valid: newMembershipValidation.valid && userNameValidation.valid,
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
            .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
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
#if !os(iOS)
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
                        fromRawTag = false
                        fromRawTagChanged(to: fromRawTag)
                        newMembership = NewMembershipCase.none
                        newMembershipChanged(to: newMembership)
                        focusedField = .userName
                    }) {
                        HStack {
                            Image(systemName: "xmark")
                                .foregroundStyle(Color.TextColorRequired, Color.TextColorSecondary)
                            Text("Clear user")
                                .font(.system(.body, design: .rounded).bold())
                                .foregroundStyle(Color.TextColorRequired, Color.TextColorSecondary)
                        }
                        .padding(4)
                        .buttonStyle(.plain)
                    }
                    .disabled(isAnyToastShowing)
                }
                ToolbarItem {
                    Menu("Theme", systemImage: "paintpalette") {
                        Picker("Theme:", selection: $theme.onChange(setTheme)) {
                            ForEach(Theme.allCases) { itemTheme in
                                if itemTheme != .notSet {
                                    Text(itemTheme.rawValue).tag(itemTheme)
                                }
                            }
                        }
                        .pickerStyle(.inline)
                    }
                    .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                    .disabled(isAnyToastShowing)
                }
            }
#endif
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
#if os(iOS)
        .frame(minHeight: 600)
#else
        .frame(minWidth: 1024, minHeight: 600)
#endif
        .background(Color.BackgroundColor)
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
                    subTitle: getVersionToastSubtitle())
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
                    type: .systemImage("xmark.octagon.fill", .TextColorRequired),
                    title: "New version required",
                    subTitle: getVersionToastSubtitle())
            },
            onTap: {
                if let url = URL(string: appState.versionCheckToast.wrappedValue.linkToCurrentVersion) {
                    openURL(url)
#if !os(iOS)
                    NSApplication.shared.terminate(nil)
#endif
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

                DispatchQueue.main.async {
                    setTheme(UserDefaultsUtils.shared.getTheme())
                }

                do {
#if TESTING
                    let pagesUrl = URL(
                        string: "https://vero.andydragon.com/static/data/testing/pages.json")!
#else
                    let pagesUrl = URL(string: "https://vero.andydragon.com/static/data/pages.json")!
#endif
                    let pagesCatalog = try await URLSession.shared.decode(SciptsCatalog.self, from: pagesUrl)
                    var pages = [LoadedPage]()
                    for hubPair in (pagesCatalog.hubs) {
                        for hubPage in hubPair.value {
                            pages.append(LoadedPage.from(hub: hubPair.key, page: hubPage))
                        }
                    }
                    loadedPages.removeAll()
                    loadedPages.append(contentsOf: pages.sorted(by: {
                        if $0.hub == "other" && $1.hub == "other" {
                            return $0.name < $1.name
                        }
                        if $0.hub == "other" {
                            return false
                        }
                        if $1.hub == "other" {
                            return true
                        }
                        return "\($0.hub)_\($0.name)" < "\($1.hub)_\($1.name)"
                    }))

                    // Delay the start of the templates download so the window can be ready faster
                    try await Task.sleep(nanoseconds: 1_000_000_000)

#if TESTING
                    let templatesUrl = URL(
                        string: "https://vero.andydragon.com/static/data/testing/templates.json")!
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
                        let disallowListUrl = URL(
                            string: "https://vero.andydragon.com/static/data/testing/disallowlist.json")!
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
                    alertMessage = "The application requires the catalog to perform its operations: " +
                    error.localizedDescription
                    terminalAlert = true
                    showingAlert = true
                }
            }
            .preferredColorScheme(isDarkModeOn ? /*@START_MENU_TOKEN@*/.dark/*@END_MENU_TOKEN@*/ : .light)
    }

    func setTheme(_ newTheme: Theme) {
        if (newTheme == .notSet) {
            isDarkModeOn = colorScheme == .dark
        } else {
            if let details = ThemeDetails[newTheme] {
                Color.currentTheme = details.colorTheme
                isDarkModeOn = details.darkTheme
                theme = newTheme
                UserDefaultsUtils.shared.setTheme(theme: newTheme)
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

    func getVersionToastSubtitle() -> String {
        let appVersion = appState.versionCheckToast.wrappedValue.appVersion
        let currentVersion = appState.versionCheckToast.wrappedValue.currentVersion
        let linkAvailable = appState.versionCheckToast.wrappedValue.linkToCurrentVersion.isEmpty
        var availableOrRequired: String
        var optionInstruction: String
        if appState.isShowingVersionAvailableToast.wrappedValue {
            availableOrRequired = "available"
            optionInstruction = " (this will go away in 10 seconds)"
        } else {
            availableOrRequired = "required"
            optionInstruction = " or ⌘ + Q to Quit"
        }
        return String {
            "You are using v\(appVersion) "
            "and v\(currentVersion) is \(availableOrRequired)"
            "\(linkAvailable ? "" : ", click here to open your browser")"
            optionInstruction
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
        if !MembershipCase.caseValidFor(hub: currentPage?.hub, value) {
            return (false, "Not a valid value")
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

    func fromRawTagChanged(to value: Bool) {
        updateScripts()
    }

    func newMembershipChanged(to value: NewMembershipCase) {
        updateNewMembershipScripts()
    }

    func validateNewMembership(value: NewMembershipCase) -> (valid: Bool, reason: String?) {
        if !NewMembershipCase.caseValidFor(hub: currentPage?.hub, value) {
            return (false, "Not a valid value")
        }
        return (true, nil)
    }

    func copyScript(
        _ script: String,
        _ placeholders: PlaceholderList,
        _ otherPlaceholders: [PlaceholderList],
        force: Bool = false,
        withPlaceholders: Bool = false
    ) -> Bool {
        scriptWithPlaceholders = script
        scriptWithPlaceholdersInPlace = script
        placeholders.placeholderDict.forEach({ placeholder in
            scriptWithPlaceholders = scriptWithPlaceholders.replacingOccurrences(
                of: placeholder.key, with: placeholder.value.value)
        })
        if withPlaceholders {
            copyToClipboard(scriptWithPlaceholdersInPlace)
            return true
        } else if !checkForPlaceholders(
            scriptWithPlaceholdersInPlace,
            placeholders,
            otherPlaceholders,
            force: force
        ) {
            copyToClipboard(scriptWithPlaceholders)
            return true
        }
        return false
    }

    func transferPlaceholderValues(
        _ scriptPlaceholders: PlaceholderList,
        _ otherPlaceholders: [PlaceholderList]
    ) -> Void {
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

    func checkForPlaceholders(
        _ script: String,
        _ placeholders: PlaceholderList,
        _ otherPlaceholders: [PlaceholderList],
        force: Bool = false
    ) -> Bool {
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
                        if (value == nil || value!.isEmpty)
                            && sourcePlaceholderEntry != nil
                            && !(sourcePlaceholderEntry?.value ?? "").isEmpty {
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
        var currentPageName = page
        var scriptPageName = currentPageName
        let currentHubName = currentPage?.hub
        if currentPageName != "" {
            let pageSource = loadedPages.first(where: { needle in needle.id == page })
            if pageSource != nil {
                currentPageName = pageSource?.name ?? page
                scriptPageName = currentPageName
                if pageSource?.pageName != nil {
                    scriptPageName = (pageSource?.pageName)!
                }
            }
            currentPage = pageSource
        } else {
            currentPage = nil
        }
        // There was a hub change, re-validate the membership and new membership
        if currentPage?.hub != currentHubName {
            membership = MembershipCase.none
            lastMembership = membership
            membershipValidation = validateMembership(value: membership)
            newMembership = NewMembershipCase.none
            newMembershipValidation = validateNewMembership(value: newMembership)
            newMembershipChanged(to: newMembership)
        }
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
            let featureScriptTemplate = getTemplateFromCatalog(
                "feature",
                from: page,
                firstFeature: firstForPage,
                rawTag: fromRawTag,
                communityTag: fromCommunityTag) ?? ""
            let commentScriptTemplate = getTemplateFromCatalog(
                "comment",
                from: page,
                firstFeature: firstForPage,
                rawTag: fromRawTag,
                communityTag: fromCommunityTag) ?? ""
            let originalPostScriptTemplate = getTemplateFromCatalog(
                "original post",
                from: page,
                firstFeature: firstForPage,
                rawTag: fromRawTag,
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

    func getTemplateFromCatalog(
        _ templateName: String,
        from pageId: String,
        firstFeature: Bool,
        rawTag: Bool,
        communityTag: Bool
    ) -> String! {
        var template: Template!
        if waitingForTemplates {
            return "";
        }
        let templatePage = templatesCatalog.pages.first(where: { page in
            page.id == pageId
        });

        // check first feature AND raw AND community
        if firstFeature && rawTag && communityTag {
            template = templatePage?.templates.first(where: { template in
                template.name == "first raw community " + templateName
            })
        }

        // next check first feature AND raw
        if firstFeature && rawTag && template == nil {
            template = templatePage?.templates.first(where: { template in
                template.name == "first raw " + templateName
            })
        }

        // next check first feature AND community
        if firstFeature && communityTag && template == nil {
            template = templatePage?.templates.first(where: { template in
                template.name == "first community " + templateName
            })
        }

        // next check first feature
        if firstFeature && template == nil {
            template = templatePage?.templates.first(where: { template in
                template.name == "first " + templateName
            })
        }

        // next check raw
        if rawTag && template == nil {
            template = templatePage?.templates.first(where: { template in
                template.name == "raw " + templateName
            })
        }

        // next check raw AND community
        if rawTag && communityTag && template == nil {
            template = templatePage?.templates.first(where: { template in
                template.name == "raw community " + templateName
            })
        }

        // next check community
        if communityTag && template == nil {
            template = templatePage?.templates.first(where: { template in
                template.name == "community " + templateName
            })
        }

        // last check standard
        if template == nil {
            template = templatePage?.templates.first(where: { template in
                template.name == templateName
            })
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
            if newMembership != NewMembershipCase.none {
                if !userNameValidation.valid {
                    validationErrors += "User: " + userNameValidation.reason! + "\n"
                }
                if !newMembershipValidation.valid {
                    validationErrors += "New level: " + newMembershipValidation.reason! + "\n"
                }
            }
            newMembershipScript = validationErrors
        } else {
            let templateName = "\(currentPage?.hub ?? ""):\(newMembership.rawValue.replacingOccurrences(of: " ", with: "_").lowercased())"
            let template = templatesCatalog.specialTemplates.first(where: { template in
                template.name == templateName
            })
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
