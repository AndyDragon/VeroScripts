//
//  ContentView.swift
//  Vero Scripts
//
//  Created by Andrew Forget on 2024-01-03.
//

import SwiftUI
import SwiftyBeaver
import CloudKit

public extension Color {
#if os(macOS)
    static let backgroundColor = Color(NSColor.windowBackgroundColor)
    static let secondaryBackgroundColor = Color(NSColor.controlBackgroundColor)
#else
    static let backgroundColor = Color(UIColor.systemBackground)
    static let secondaryBackgroundColor = Color(UIColor.secondarySystemBackground)
#endif
}

struct ContentView: View {
    @Environment(\.openURL) private var openURL

    @State private var viewModel = ViewModel()

    @State private var loadedPages = [LoadedPage]()
    @State private var waitingForTemplates = true
    @State private var templatesCatalog = TemplateCatalog(pages: [], specialTemplates: [])
    @State private var disallowLists = [String:[String]]()
    @State private var cautionLists = [String:[String]]()

//    @State private var page = UserDefaults.standard.string(forKey: "Page") ?? ""
    @State private var currentPage: LoadedPage? = nil
    @State private var pageValidation: (validation: ValidationResult, reason: String?) = (.valid, nil)
    @State private var pageStaffLevel = StaffLevelCase.mod

    @State private var yourName = UserDefaults.standard.string(forKey: "YourName") ?? ""
    @State private var yourNameValidation: (validation: ValidationResult, reason: String?) = (.valid, nil)
    @State private var yourFirstName = UserDefaults.standard.string(forKey: "YourFirstName") ?? ""
    @State private var yourFirstNameValidation: (validation: ValidationResult, reason: String?) = (.valid, nil)

    @State private var userName = ""
    @State private var userNameValidation: (validation: ValidationResult, reason: String?) = (.valid, nil)
    @State private var membership = MembershipCase.none
    @State private var membershipValidation: (validation: ValidationResult, reason: String?) = (.valid, nil)
    @State private var firstForPage = false
    @State private var fromCommunityTag = false
    @State private var fromHubTag = false
    @State private var fromRawTag = false

    @State private var featureScript = ""
    @State private var commentScript = ""
    @State private var originalPostScript = ""

    @State private var newMembership = NewMembershipCase.none
    @State private var newMembershipValidation: (validation: ValidationResult, reason: String?) = (.valid, nil)
    @State private var newMembershipScript = ""

    @State private var placeholderSheetCase = PlaceholderSheetCase.featureScript
    @State private var showingPlaceholderSheet = false

    @ObservedObject private var featureScriptPlaceholders = PlaceholderList()
    @ObservedObject private var commentScriptPlaceholders = PlaceholderList()
    @ObservedObject private var originalPostScriptPlaceholders = PlaceholderList()
    @State private var scriptWithPlaceholdersInPlace = ""
    @State private var scriptWithPlaceholders = ""

    @State private var lastPage: LoadedPage?
    @State private var lastPageStaffLevel = StaffLevelCase.mod
    @State private var lastYourName = ""
    @State private var lastYourFirstName = ""
    @State private var lastUserName = ""
    @State private var lastMembership = MembershipCase.none

    @FocusState private var focusedField: FocusedField?

    private var canCopyScripts: Bool {
        return membershipValidation.validation != .error
        && userNameValidation.validation != .error
        && yourNameValidation.validation != .error
        && yourFirstNameValidation.validation != .error
        && pageValidation.validation != .error
    }
    private var canCopyNewMembershipScript: Bool {
        return newMembership != NewMembershipCase.none
        && newMembershipValidation.validation != .error
        && userNameValidation.validation != .error
    }
    private let accordionHeightRatio = 3.5
    private let logger = SwiftyBeaver.self

#if STANDALONE
    private let appState: VersionCheckAppState
    init(_ appState: VersionCheckAppState) {
        self.appState = appState
    }
#endif
    
    var body: some View {
        ZStack {
            Color.backgroundColor.edgesIgnoringSafeArea(.all)

            VStack {
                // Page and staff level
                PageAndStaffLevelView()

                // You and your first name
                ModeratorView()

                // User, membership and options
                UserAndOptionsView()

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
                            withPlaceholders: withPlaceholders
                        ) {
                            logger.verbose("Copied feature script to clipboard", context: "User")
                            viewModel.showSuccessToast(
                                "Copied",
                                String {
                                    "Copied the feature script\(withPlaceholders ? " with placeholders" : "") "
                                    "to the clipboard"
                                }
                            )
                        }
                    },
                    focus: $focusedField,
                    focusField: .featureScript
                )

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
                            withPlaceholders: withPlaceholders
                        ) {
                            logger.verbose("Copied comment script to clipboard", context: "User")
                            viewModel.showSuccessToast(
                                "Copied",
                                String {
                                    "Copied the comment script\(withPlaceholders ? " with placeholders" : "") "
                                    "to the clipboard"
                                }
                            )
                        }
                    },
                    focus: $focusedField,
                    focusField: .commentScript
                )

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
                            withPlaceholders: withPlaceholders
                        ) {
                            logger.verbose("Copied original post script to clipboard", context: "User")
                            viewModel.showSuccessToast(
                                "Copied",
                                String {
                                    "Copied the original script\(withPlaceholders ? " with placeholders" : "") "
                                    "to the clipboard"
                                }
                            )
                        }
                    },
                    focus: $focusedField,
                    focusField: .originalPostScript
                )

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
                    valid: newMembershipValidation.validation != .error && userNameValidation.validation != .error,
                    canCopy: canCopyNewMembershipScript,
                    copy: {
                        copyToClipboard(newMembershipScript)
                        logger.verbose("Copied new membership script to clipboard", context: "User")
                        viewModel.showSuccessToast(
                            "Copied",
                            "Copied the new membership script to the clipboard"
                        )
                    },
                    focus: $focusedField,
                    focusField: .newMembershipScript
                )
            }
            .foregroundStyle(Color.label, Color.secondaryLabel)
            .padding()
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
                        logger.verbose("Copied \(scriptName) script to clipboard", context: "User")
                        viewModel.showSuccessToast("Copied", "Copied the \(scriptName) script\(suffix) to the clipboard")
                    }
                )
            }
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        logger.verbose("Tapped clear user", context: "User")
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
                        fromHubTag = false
                        fromHubTagChanged(to: fromHubTag)
                        fromRawTag = false
                        fromRawTagChanged(to: fromRawTag)
                        newMembership = NewMembershipCase.none
                        newMembershipChanged(to: newMembership)
                        focusedField = .userName
                        logger.verbose("Cleared user", context: "System")
                    }) {
                        HStack {
                            Image(systemName: "xmark")
                                .foregroundStyle(Color.red, Color.secondaryLabel)
                            Text("Clear user")
                                .font(.system(.body, design: .rounded).bold())
                                .foregroundStyle(Color.red, Color.secondaryLabel)
                        }
                        .padding(4)
                        .buttonStyle(.plain)
                    }
                    .disabled(viewModel.hasModalToasts)
                }
            }
        }
        .frame(minWidth: 1024, minHeight: 600)
        .background(Color.backgroundColor)
        .advancedToastView(toasts: $viewModel.toastViews)
#if STANDALONE
        .attachVersionCheckState(viewModel, appState) { url in
            openURL(url)
        }
        .navigationTitle("Vero Scripts - Standalone Version")
#endif
        .task {
            // Hack for page staff level to handle changes (otherwise they are not persisted)
            lastPageStaffLevel = pageStaffLevel

            let loadingPagesToast = viewModel.showToast(
                .progress,
                "Loading pages...",
                "Loading the page catalog from the server"
            )

            await loadPages()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                viewModel.dismissToast(loadingPagesToast)
            }
        }
    }
    
    fileprivate func PageAndStaffLevelView() -> some View {
        HStack {
            // Page picker
            if pageValidation.validation != .valid {
                Image(systemName: pageValidation.validation.icon)
                    .foregroundStyle(pageValidation.validation.iconColor1, pageValidation.validation.iconColor2)
                    .help(pageValidation.reason ?? "unknown error")
                    .imageScale(.small)
            }
            Text("Page: ")
                .foregroundStyle(pageValidation.validation.color, Color.secondaryLabel)
                .frame(width: 36, alignment: .leading)
                .lineLimit(1)
                .truncationMode(.tail)
            Picker("", selection: $currentPage.onChange { value in
                if currentPage == nil {
                    pageValidation = (.error, "Page is required")
                } else {
                    pageValidation = (.valid, nil)
                }
                pageChanged(to: value)
            }) {
                ForEach(loadedPages) { page in
                    Text(page.displayName)
                        .tag(page)
                        .foregroundStyle(Color.secondaryLabel, Color.secondaryLabel)
                }
            }
            .tint(Color.accentColor)
            .accentColor(Color.accentColor)
            .foregroundStyle(Color.accentColor, Color.label)
            .focusable()
            .focused($focusedField, equals: .page)
            .onAppear {
                if currentPage == nil {
                    pageValidation = (.error, "Page must not be 'default' or a page name is required")
                } else {
                    pageValidation = (.valid, nil)
                }
            }

            // Page staff level picker
            Text("Page staff level: ")
                .padding([.leading], 8)
                .lineLimit(1)
                .truncationMode(.tail)
            Picker("", selection: $pageStaffLevel.onChange(pageStaffLevelChanged)) {
                ForEach(StaffLevelCase.casesFor(hub: currentPage?.hub)) { staffLevelCase in
                    Text(staffLevelCase.rawValue)
                        .tag(staffLevelCase)
                        .foregroundStyle(Color.secondaryLabel, Color.secondaryLabel)
                }
            }
            .tint(Color.accentColor)
            .accentColor(Color.accentColor)
            .foregroundStyle(Color.accentColor, Color.label)
            .focusable()
            .focused($focusedField, equals: .staffLevel)
        }
    }

    fileprivate func ModeratorView() -> some View {
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
                        return (.error, "Required value")
                    } else if value.first! == "@" {
                        return (.error, "Don't include the '@' in user names")
                    } else if value.contains(" ") {
                        return (.error, "Spaces are not allowed")
                    }
                    return (.valid, nil)
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
                        return (.error, "Required value")
                    }
                    return (.valid, nil)
                },
                focus: $focusedField,
                focusField: .yourFirstName
            ).padding([.leading], 8)
        }
    }
    
    fileprivate func UserAndOptionsView() -> some View {
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
            
            Button(action: {
                if let postLink = stringFromClipboard(), postLink.starts(with: "https://vero.co/") {
                    let possibleUserAlias = String(postLink.dropFirst(16).split(separator: "/").first ?? "")
                    // If the user doesn't have an alias, the link will have a single letter, often 'p'
                    if possibleUserAlias.count > 1 {
                        logger.verbose("Using the link text for the user alias", context: "System")
                        userName = possibleUserAlias
                        userNameChanged(to: userName)
                        userNameValidation = validateUserName(value: userName)
                    } else {
                        viewModel.showToast(.warning, "No user name", "The VERO post link did not contain a user name", duration: 4, modal: false)
                    }
                } else {
                    viewModel.showToast(.warning, "Not VERO link", "Clipboard did not contain VERO post link", duration: 4, modal: false)
                }
            }) {
                Label("Paste from post link", systemImage: "link")
                    .padding(.horizontal, 8)
            }
            
            // User level picker
            if membershipValidation.validation != .valid {
                Image(systemName: membershipValidation.validation.icon)
                    .foregroundStyle(membershipValidation.validation.iconColor1, membershipValidation.validation.iconColor2)
                    .help(membershipValidation.reason ?? "unknown error")
                    .imageScale(.small)
                    .padding([.leading], 8)
            }
            Text("Level: ")
                .foregroundStyle(membershipValidation.validation.color, Color.secondaryLabel)
                .frame(width: 36, alignment: .leading)
                .padding([.leading], membershipValidation.validation == .valid ? 8 : 0)
            Picker("", selection: $membership.onChange { value in
                membershipValidation = validateMembership(value: membership)
                membershipChanged(to: value)
            }) {
                ForEach(MembershipCase.casesFor(hub: currentPage?.hub)) { level in
                    Text(level.rawValue)
                        .tag(level)
                        .foregroundStyle(Color.secondaryLabel, Color.secondaryLabel)
                }
            }
            .tint(Color.accentColor)
            .accentColor(Color.accentColor)
            .foregroundStyle(Color.accentColor, Color.label)
            .onAppear {
                membershipValidation = validateMembership(value: membership)
            }
            .focusable()
            .focused($focusedField, equals: .level)
            
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
            
            if currentPage?.hub == "click" {
                Toggle(isOn: $fromCommunityTag.onChange(fromCommunityTagChanged)) {
                    Text("From community tag")
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .focusable()
                .focused($focusedField, equals: .communityTag)
                .padding([.leading], 8)
                .help("From community tag")
                
                Toggle(isOn: $fromHubTag.onChange(fromHubTagChanged)) {
                    Text("From hub tag")
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .focusable()
                .focused($focusedField, equals: .hubTag)
                .padding([.leading], 8)
                .help("From hub tag")
            } else if currentPage?.hub == "snap" {
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
            
            Spacer()
        }
    }
    
    private func updateStaffLevelForPage() {
        if let currentPage {
            if let rawPageStaffLevel = UserDefaults.standard.string(forKey: "StaffLevel_" + currentPage.displayName) {
                if let pageStaffLevelFromRaw = StaffLevelCase(rawValue: rawPageStaffLevel) {
                    pageStaffLevel = pageStaffLevelFromRaw
                    return
                }
                pageStaffLevel = StaffLevelCase.mod
                return
            }
        }

        if let rawPagelessStaffLevel = UserDefaults.standard.string(forKey: "StaffLevel") {
            if let pageStaffLevelFromRaw = StaffLevelCase(rawValue: rawPagelessStaffLevel) {
                pageStaffLevel = pageStaffLevelFromRaw
                storeStaffLevelForPage()
                return
            }
        }

        pageStaffLevel = StaffLevelCase.mod
        storeStaffLevelForPage()
    }

    private func storeStaffLevelForPage() {
        if let currentPage {
            UserDefaults.standard.set(pageStaffLevel.rawValue, forKey: "StaffLevel_" + currentPage.displayName)
        } else {
            UserDefaults.standard.set(pageStaffLevel.rawValue, forKey: "StaffLevel")
        }
    }

    private func loadPages() async {
        logger.verbose("Loading page catalog from server", context: "System")

        do {
            let pagesUrl = URL(string: "https://vero.andydragon.com/static/data/pages.json")!
            let pagesCatalog = try await URLSession.shared.decode(ScriptsCatalog.self, from: pagesUrl)
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

            let page = UserDefaults.standard.string(forKey: "Page") ?? ""
            currentPage = loadedPages.first(where: { $0.displayName == page }) ?? loadedPages.first
            if currentPage == nil {
                pageValidation = (.error, "Page must not be 'default' or a page name is required")
            } else {
                pageValidation = (.valid, nil)
            }

            logger.verbose("Loaded page catalog from server with \(loadedPages.count) pages", context: "System")

            updateStaffLevelForPage()

            // Delay the start of the templates download so the window can be ready faster
            try await Task.sleep(nanoseconds: 200_000_000)

            logger.verbose("Loading template catalog from server", context: "System")

            let templatesUrl = URL(string: "https://vero.andydragon.com/static/data/templates.json")!
            templatesCatalog = try await URLSession.shared.decode(TemplateCatalog.self, from: templatesUrl)
            waitingForTemplates = false
            updateScripts()
            updateNewMembershipScripts()

            logger.verbose("Loaded template catalog from server with \(templatesCatalog.pages.count) page templates", context: "System")

            do {
                // Delay the start of the disallowed lists download so the window can be ready faster
                try await Task.sleep(nanoseconds: 1_000_000_000)

                logger.verbose("Loading disallow lists from server", context: "System")

                let disallowListsUrl = URL(string: "https://vero.andydragon.com/static/data/disallowlists.json")!
                disallowLists = try await URLSession.shared.decode([String: [String]].self, from: disallowListsUrl)

                logger.verbose("Loaded disallow lists from server with \(disallowLists.count) entries", context: "System")
            } catch {
                // do nothing, the disallow list is not critical
                logger.error("Failed to load disallow list from server: \(error.localizedDescription)", context: "System")
                debugPrint(error.localizedDescription)
            }

            do {
                logger.verbose("Loading caution lists from server", context: "System")

                let cautionListsUrl = URL(string: "https://vero.andydragon.com/static/data/cautionlists.json")!
                cautionLists = try await URLSession.shared.decode([String: [String]].self, from: cautionListsUrl)

                logger.verbose("Loaded caution lists from server with \(cautionLists.count) entries", context: "System")
            } catch {
                // do nothing, the caution lists is not critical
                logger.error("Failed to load caution lists from server: \(error.localizedDescription)", context: "System")
                debugPrint(error.localizedDescription)
            }

            updateScripts()
            updateNewMembershipScripts()
            
#if STANDALONE
            do {
                // Delay the start of the disallowed list download so the window can be ready faster
                try await Task.sleep(nanoseconds: 100_000_000)

                appState.checkForUpdates()
            } catch {
                // do nothing, the version check is not critical
                debugPrint(error.localizedDescription)
            }
#endif
        } catch {
            logger.error("Failed to load page catalog or template catalog from server: \(error.localizedDescription)", context: "System")
            viewModel.dismissAllNonBlockingToasts(includeProgress: true)
            viewModel.showToast(
                .fatal,
                "Failed to load pages",
                "The application requires the catalog to perform its operations: \(error.localizedDescription)\n\n" +
                "Click here to try again immediately or wait 15 seconds to automatically try again.",
                duration: 15,
                width: 720,
                buttonTitle: "Retry",
                onButtonTapped: {
                    logger.verbose("Retrying to load pages catalog after failure", context: "System")
                    DispatchQueue.main.async {
                        Task {
                            await loadPages()
                        }
                    }
                },
                onDismissed: {
                    logger.verbose("Retrying to load pages catalog after failure", context: "System")
                    DispatchQueue.main.async {
                        Task {
                            await loadPages()
                        }
                    }
                }
            )
        }
    }

    private func clearPlaceholders() {
        featureScriptPlaceholders.placeholderDict.removeAll()
        featureScriptPlaceholders.longPlaceholderDict.removeAll()
        commentScriptPlaceholders.placeholderDict.removeAll()
        commentScriptPlaceholders.longPlaceholderDict.removeAll()
        originalPostScriptPlaceholders.placeholderDict.removeAll()
        originalPostScriptPlaceholders.longPlaceholderDict.removeAll()
    }

    private func membershipChanged(to value: MembershipCase) {
        if value != lastMembership {
            clearPlaceholders()
            updateScripts()
            updateNewMembershipScripts()
            lastMembership = value
        }
    }

    private func validateMembership(value: MembershipCase) -> (validation: ValidationResult, reason: String?) {
        if value == MembershipCase.none {
            return (.error, "Required value")
        }
        if !MembershipCase.caseValidFor(hub: currentPage?.hub, value) {
            return (.error, "Not a valid value")
        }
        return (.valid, nil)
    }

    private func userNameChanged(to value: String) {
        if value != lastUserName {
            clearPlaceholders()
            updateScripts()
            updateNewMembershipScripts()
            lastUserName = value
        }
    }

    private func validateUserName(value: String) -> (validation: ValidationResult, reason: String?) {
        if value.count == 0 {
            return (.error, "Required value")
        } else if value.first! == "@" {
            return (.error, "Don't include the '@' in user names")
        } else if (disallowLists[currentPage?.hub ?? ""]?.first { disallow in disallow == value } != nil) {
            return (.error, "User is on the disallow list")
        } else if (cautionLists[currentPage?.hub ?? ""]?.first { caution in caution == value } != nil) {
            return (.warning, "User is on the caution list")
        } else if value.contains(" ") {
            return (.error, "Spaces are not allowed")
        }
        return (.valid, nil)
    }

    private func yourNameChanged(to value: String) {
        if value != lastYourName {
            clearPlaceholders()
            UserDefaults.standard.set(yourName, forKey: "YourName")
            updateScripts()
        updateNewMembershipScripts()
            lastYourName = value
        }
    }

    private func yourFirstNameChanged(to value: String) {
        if value != lastYourFirstName {
            clearPlaceholders()
            UserDefaults.standard.set(yourFirstName, forKey: "YourFirstName")
            updateScripts()
            updateNewMembershipScripts()
            lastYourFirstName = value
        }
    }

    private func pageChanged(to value: LoadedPage?) {
        if value != lastPage {
            clearPlaceholders()
            UserDefaults.standard.set(currentPage?.displayName, forKey: "Page")
            updateStaffLevelForPage()
            userNameValidation = validateUserName(value: userName)
            if !MembershipCase.caseValidFor(hub: currentPage?.hub, membership) {
                membership = .none
                membershipValidation = validateMembership(value: membership)
                membershipChanged(to: membership)
            }
            updateScripts()
            updateNewMembershipScripts()
            lastPage = value
        }
    }

    private func pageStaffLevelChanged(to value: StaffLevelCase) {
        if value != lastPageStaffLevel {
            clearPlaceholders()
            storeStaffLevelForPage()
            updateScripts()
            updateNewMembershipScripts()
            lastPageStaffLevel = value
        } else {
            storeStaffLevelForPage()
        }
    }

    private func firstForPageChanged(to value: Bool) {
        updateScripts()
        updateNewMembershipScripts()
    }

    private func fromCommunityTagChanged(to value: Bool) {
        updateScripts()
        updateNewMembershipScripts()
    }

    private func fromRawTagChanged(to value: Bool) {
        updateScripts()
        updateNewMembershipScripts()
    }

    private func fromHubTagChanged(to value: Bool) {
        updateScripts()
        updateNewMembershipScripts()
    }

    private func newMembershipChanged(to value: NewMembershipCase) {
        updateNewMembershipScripts()
    }

    private func validateNewMembership(value: NewMembershipCase) -> (validation: ValidationResult, reason: String?) {
        if !NewMembershipCase.caseValidFor(hub: currentPage?.hub, value) {
            return (.error, "Not a valid value")
        }
        return (.valid, nil)
    }

    private func copyScript(
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
        placeholders.longPlaceholderDict.forEach({ placeholder in
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

    private func transferPlaceholderValues(
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
        scriptPlaceholders.longPlaceholderDict.forEach { placeholder in
            otherPlaceholders.forEach { destinationPlaceholders in
                let destinationPlaceholderEntry = destinationPlaceholders.longPlaceholderDict[placeholder.key]
                if destinationPlaceholderEntry != nil {
                    destinationPlaceholderEntry!.value = placeholder.value.value
                }
            }
        }
    }

    private func scriptHasPlaceholders(_ script: String) -> Bool {
        return !matches(of: "\\[\\[([^\\]]*)\\]\\]", in: script).isEmpty || !matches(of: "\\[\\{([^\\}]*)\\}\\]", in: script).isEmpty
    }

    private func checkForPlaceholders(
        _ script: String,
        _ placeholders: PlaceholderList,
        _ otherPlaceholders: [PlaceholderList],
        force: Bool = false
    ) -> Bool {
        var needEditor: Bool = false
        var foundPlaceholders: [String] = [];
        foundPlaceholders.append(contentsOf: matches(of: "\\[\\[([^\\]]*)\\]\\]", in: script))
        if foundPlaceholders.count != 0 {
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
        }
        var foundLongPlaceholders: [String] = [];
        foundLongPlaceholders.append(contentsOf: matches(of: "\\[\\{([^\\}]*)\\}\\]", in: script))
        if foundLongPlaceholders.count != 0 {
            for placeholder in foundLongPlaceholders {
                let placeholderEntry = placeholders.longPlaceholderDict[placeholder]
                if placeholderEntry == nil {
                    needEditor = true
                    var value: String? = nil
                    otherPlaceholders.forEach { sourcePlaceholders in
                        let sourcePlaceholderEntry = sourcePlaceholders.longPlaceholderDict[placeholder]
                        if (value == nil || value!.isEmpty)
                            && sourcePlaceholderEntry != nil
                            && !(sourcePlaceholderEntry?.value ?? "").isEmpty {
                            value = sourcePlaceholderEntry?.value
                        }
                    }
                    placeholders.longPlaceholderDict[placeholder] = PlaceholderValue()
                    if value != nil {
                        placeholders.longPlaceholderDict[placeholder]?.value = value!
                    }
                }
            }
        }
        if foundPlaceholders.count != 0 || foundLongPlaceholders.count != 0 {
            if (force || needEditor) && !showingPlaceholderSheet {
                logger.verbose("Script has manual placeholders, opening editor", context: "System")
                showingPlaceholderSheet.toggle()
                return true
            }
        }
        return false
    }

    private func updateScripts() -> Void {
        if !canCopyScripts {
            var validationErrors = ""
            if userNameValidation.validation != .valid {
                validationErrors += "User: " + userNameValidation.reason! + "\n"
            }
            if membershipValidation.validation != .valid {
                validationErrors += "Level: " + membershipValidation.reason! + "\n"
            }
            if yourNameValidation.validation != .valid {
                validationErrors += "You: " + yourNameValidation.reason! + "\n"
            }
            if yourFirstNameValidation.validation != .valid {
                validationErrors += "Your first name: " + yourFirstNameValidation.reason! + "\n"
            }
            if pageValidation.validation != .valid {
                validationErrors += "Page: " + pageValidation.reason! + "\n"
            }
            featureScript = validationErrors
            originalPostScript = ""
            commentScript = ""
        } else if let currentPage {
            let currentPageName = currentPage.id
            let currentPageDisplayName = currentPage.name
            let scriptPageName = currentPage.pageName ?? currentPageDisplayName
            let scriptPageHash = currentPage.hashTag ?? currentPageDisplayName
            let scriptPageTitle = currentPage.title ?? currentPageDisplayName
            let membershipString = membership.rawValue
            let featureScriptTemplate = getTemplateFromCatalog(
                "feature",
                from: currentPage.id,
                firstFeature: firstForPage,
                rawTag: fromRawTag,
                communityTag: fromCommunityTag,
                hubTag: fromHubTag) ?? ""
            let commentScriptTemplate = getTemplateFromCatalog(
                "comment",
                from: currentPage.id,
                firstFeature: firstForPage,
                rawTag: fromRawTag,
                communityTag: fromCommunityTag,
                hubTag: fromHubTag) ?? ""
            let originalPostScriptTemplate = getTemplateFromCatalog(
                "original post",
                from: currentPage.id,
                firstFeature: firstForPage,
                rawTag: fromRawTag,
                communityTag: fromCommunityTag,
                hubTag: fromHubTag) ?? ""
            
            featureScript = featureScriptTemplate
                .replacingOccurrences(of: "%%PAGENAME%%", with: scriptPageName)
                .replacingOccurrences(of: "%%FULLPAGENAME%%", with: currentPageName)
                .replacingOccurrences(of: "%%PAGETITLE%%", with: scriptPageTitle)
                .replacingOccurrences(of: "%%PAGEHASH%%", with: scriptPageHash)
                .replacingOccurrences(of: "%%MEMBERLEVEL%%", with: membershipString)
                .replacingOccurrences(of: "%%USERNAME%%", with: userName)
                .replacingOccurrences(of: "%%YOURNAME%%", with: yourName)
                .replacingOccurrences(of: "%%YOURFIRSTNAME%%", with: yourFirstName)
                .replacingOccurrences(of: "%%STAFFLEVEL%%", with: pageStaffLevel.rawValue)
            originalPostScript = originalPostScriptTemplate
                .replacingOccurrences(of: "%%PAGENAME%%", with: scriptPageName)
                .replacingOccurrences(of: "%%FULLPAGENAME%%", with: currentPageName)
                .replacingOccurrences(of: "%%PAGETITLE%%", with: scriptPageTitle)
                .replacingOccurrences(of: "%%PAGEHASH%%", with: scriptPageHash)
                .replacingOccurrences(of: "%%MEMBERLEVEL%%", with: membershipString)
                .replacingOccurrences(of: "%%USERNAME%%", with: userName)
                .replacingOccurrences(of: "%%YOURNAME%%", with: yourName)
                .replacingOccurrences(of: "%%YOURFIRSTNAME%%", with: yourFirstName)
                .replacingOccurrences(of: "%%STAFFLEVEL%%", with: pageStaffLevel.rawValue)
            commentScript = commentScriptTemplate
                .replacingOccurrences(of: "%%PAGENAME%%", with: scriptPageName)
                .replacingOccurrences(of: "%%FULLPAGENAME%%", with: currentPageName)
                .replacingOccurrences(of: "%%PAGETITLE%%", with: scriptPageTitle)
                .replacingOccurrences(of: "%%PAGEHASH%%", with: scriptPageHash)
                .replacingOccurrences(of: "%%MEMBERLEVEL%%", with: membershipString)
                .replacingOccurrences(of: "%%USERNAME%%", with: userName)
                .replacingOccurrences(of: "%%YOURNAME%%", with: yourName)
                .replacingOccurrences(of: "%%YOURFIRSTNAME%%", with: yourFirstName)
                .replacingOccurrences(of: "%%STAFFLEVEL%%", with: pageStaffLevel.rawValue)
        }
    }

    private func getTemplateFromCatalog(
        _ templateName: String,
        from pageId: String,
        firstFeature: Bool,
        rawTag: Bool,
        communityTag: Bool,
        hubTag: Bool
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

        // next check first feature AND hub
        if firstFeature && hubTag && template == nil {
            template = templatePage?.templates.first(where: { template in
                template.name == "first hub " + templateName
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

        // next check hub
        if hubTag && template == nil {
            template = templatePage?.templates.first(where: { template in
                template.name == "hub " + templateName
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

    private func updateNewMembershipScripts() -> Void {
        if waitingForTemplates {
            newMembershipScript = ""
            return
        }
        if !canCopyNewMembershipScript {
            var validationErrors = ""
            if newMembership != NewMembershipCase.none {
                if userNameValidation.validation != .valid {
                    validationErrors += "User: " + userNameValidation.reason! + "\n"
                }
                if newMembershipValidation.validation != .valid {
                    validationErrors += "New level: " + newMembershipValidation.reason! + "\n"
                }
            }
            newMembershipScript = validationErrors
        } else if canCopyNewMembershipScript, let currentPage {
            let currentPageName = currentPage.id
            let currentPageDisplayName = currentPage.name
            let scriptPageName = currentPage.pageName ?? currentPageDisplayName
            let scriptPageHash = currentPage.hashTag ?? currentPageDisplayName
            let scriptPageTitle = currentPage.title ?? currentPageDisplayName
            let templateName = NewMembershipCase.scriptFor(hub: currentPage.hub, newMembership)
            let template = templatesCatalog.specialTemplates.first(where: { template in
                template.name == templateName
            })
            if template == nil {
                newMembershipScript = ""
                return
            }
            newMembershipScript = template!.template
                .replacingOccurrences(of: "%%PAGENAME%%", with: scriptPageName)
                .replacingOccurrences(of: "%%FULLPAGENAME%%", with: currentPageName)
                .replacingOccurrences(of: "%%PAGETITLE%%", with: scriptPageTitle)
                .replacingOccurrences(of: "%%PAGEHASH%%", with: scriptPageHash)
                .replacingOccurrences(of: "%%USERNAME%%", with: userName)
                .replacingOccurrences(of: "%%YOURNAME%%", with: yourName)
                .replacingOccurrences(of: "%%YOURFIRSTNAME%%", with: yourFirstName)
                .replacingOccurrences(of: "%%STAFFLEVEL%%", with: pageStaffLevel.rawValue)
        } else {
            newMembershipScript = ""
        }
    }
}
