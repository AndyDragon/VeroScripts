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

    @State private var featureScript = ""
    @State private var commentScript = ""
    @State private var originalPostScript = ""
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
        return !viewModel.membershipValidation.isError
        && !viewModel.userNameValidation.isError
        && !viewModel.yourNameValidation.isError
        && !viewModel.yourFirstNameValidation.isError
        && !viewModel.pageValidation.isError
    }
    private var canCopyNewMembershipScript: Bool {
        return viewModel.newMembership != NewMembershipCase.none
        && !viewModel.newMembershipValidation.isError
        && !viewModel.userNameValidation.isError
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

            if viewModel.visibleView == .ScriptView {
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
                        newMembership: $viewModel.newMembership,
                        script: $newMembershipScript,
                        currentPage: $viewModel.currentPage,
                        minHeight: 36,
                        maxHeight: 36 * accordionHeightRatio,
                        onChanged: { newValue in
                            viewModel.newMembershipValidation = viewModel.validateNewMembership(value: viewModel.newMembership)
                            newMembershipChanged(to: newValue)
                        },
                        valid: !viewModel.newMembershipValidation.isError && !viewModel.userNameValidation.isError,
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
                .toolbar {
                    ToolbarItem {
                        Button(action: {
                            viewModel.visibleView = .PostDownloadView
                        }) {
                            HStack {
                                Image(systemName: "photo.badge.checkmark")
                                    .foregroundStyle(viewModel.postLink != nil ? Color.accentColor : Color.secondaryLabel, Color.secondaryLabel)
                                Text("Load photos")
                                    .font(.system(.body, design: .rounded).bold())
                                    .foregroundStyle(viewModel.postLink != nil ? Color.accentColor : Color.secondaryLabel, Color.secondaryLabel)
                            }
                            .padding(4)
                            .padding(.trailing, 4)
                            .buttonStyle(.plain)
                        }
                        .disabled(viewModel.postLink == nil)
                    }
                    ToolbarItem {
                        Button(action: {
                            logger.verbose("Tapped clear user", context: "User")
                            viewModel.userName = ""
                            userNameChanged(to: viewModel.userName)
                            viewModel.membership = MembershipCase.none
                            membershipChanged(to: viewModel.membership)
                            viewModel.firstForPage = false
                            firstForPageChanged(to: viewModel.firstForPage)
                            viewModel.fromCommunityTag = false
                            fromCommunityTagChanged(to: viewModel.fromCommunityTag)
                            viewModel.fromHubTag = false
                            fromHubTagChanged(to: viewModel.fromHubTag)
                            viewModel.fromRawTag = false
                            fromRawTagChanged(to: viewModel.fromRawTag)
                            viewModel.newMembership = NewMembershipCase.none
                            newMembershipChanged(to: viewModel.newMembership)
                            focusedField = .userName
                            viewModel.postLink = nil
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
            } else if viewModel.visibleView == .PostDownloadView {
                PostDownloaderView(
                    viewModel,
                    {
                        print("Should be updating scripts...")
                        clearPlaceholders()
                        updateScripts()
                        updateNewMembershipScripts()
                    },
                    $focusedField)
            } else if viewModel.visibleView == .ImageValidationView {
                ImageValidationView(
                    viewModel,
                    $focusedField)
            }
        }
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
            lastPageStaffLevel = viewModel.pageStaffLevel

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
            if !viewModel.pageValidation.isValid {
                viewModel.pageValidation.getImage()
            }
            Text("Page: ")
                .foregroundStyle(viewModel.pageValidation.getColor(), Color.secondaryLabel)
                .frame(width: 36, alignment: .leading)
                .lineLimit(1)
                .truncationMode(.tail)
            Picker("", selection: $viewModel.currentPage.onChange { value in
                pageChanged(to: value)
            }) {
                ForEach(viewModel.loadedPages) { page in
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
                if viewModel.currentPage == nil {
                    viewModel.pageValidation = .error("Page must not be 'default' or a page name is required")
                } else {
                    viewModel.pageValidation = .valid
                }
            }

            // Page staff level picker
            Text("Page staff level: ")
                .padding([.leading], 8)
                .lineLimit(1)
                .truncationMode(.tail)
            Picker("", selection: $viewModel.pageStaffLevel.onChange(pageStaffLevelChanged)) {
                ForEach(StaffLevelCase.casesFor(hub: viewModel.currentPage?.hub)) { staffLevelCase in
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
                field: $viewModel.yourName,
                fieldChanged: yourNameChanged,
                fieldValidation: $viewModel.yourNameValidation,
                validate: viewModel.validateYourName,
                focus: $focusedField,
                focusField: .yourName
            )
            
            // Your first name editor
            FieldEditor(
                title: "Your first name:",
                placeholder: "Enter your first name (capitalized)",
                field: $viewModel.yourFirstName,
                fieldChanged: yourFirstNameChanged,
                fieldValidation: $viewModel.yourFirstNameValidation,
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
                field: $viewModel.userName,
                fieldChanged: userNameChanged,
                fieldValidation: $viewModel.userNameValidation,
                validate: viewModel.validateUserName,
                focus: $focusedField,
                focusField: .userName
            )
            
            Button(action: {
                if let postLink = stringFromClipboard(), postLink.starts(with: "https://vero.co/") {
                    viewModel.postLink = postLink
                    let possibleUserAlias = String(postLink.dropFirst(16).split(separator: "/").first ?? "")
                    // If the user doesn't have an alias, the link will have a single letter, often 'p'
                    if possibleUserAlias.count > 1 {
                        logger.verbose("Using the link text for the user alias", context: "System")
                        viewModel.userName = possibleUserAlias
                        userNameChanged(to: viewModel.userName)
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
            if !viewModel.membershipValidation.isValid {
                viewModel.membershipValidation.getImage()
            }
            Text("Level: ")
                .foregroundStyle(viewModel.membershipValidation.getColor(), Color.secondaryLabel)
                .frame(width: 36, alignment: .leading)
                .padding([.leading], viewModel.membershipValidation.isValid ? 8 : 0)
            Picker("", selection: $viewModel.membership.onChange { value in
                membershipChanged(to: value)
            }) {
                ForEach(MembershipCase.casesFor(hub: viewModel.currentPage?.hub)) { level in
                    Text(level.rawValue)
                        .tag(level)
                        .foregroundStyle(Color.secondaryLabel, Color.secondaryLabel)
                }
            }
            .tint(Color.accentColor)
            .accentColor(Color.accentColor)
            .foregroundStyle(Color.accentColor, Color.label)
            .onAppear {
                viewModel.membershipValidation = viewModel.validateMembership(value: viewModel.membership)
            }
            .focusable()
            .focused($focusedField, equals: .level)
            
            // Options
            Toggle(isOn: $viewModel.firstForPage.onChange(firstForPageChanged)) {
                Text("First feature on page")
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .focusable()
            .focused($focusedField, equals: .firstFeature)
            .padding([.leading], 8)
            .help("First feature on page")
            
            if viewModel.currentPage?.hub == "click" {
                Toggle(isOn: $viewModel.fromCommunityTag.onChange(fromCommunityTagChanged)) {
                    Text("From community tag")
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .focusable()
                .focused($focusedField, equals: .communityTag)
                .padding([.leading], 8)
                .help("From community tag")
                
                Toggle(isOn: $viewModel.fromHubTag.onChange(fromHubTagChanged)) {
                    Text("From hub tag")
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .focusable()
                .focused($focusedField, equals: .hubTag)
                .padding([.leading], 8)
                .help("From hub tag")
            } else if viewModel.currentPage?.hub == "snap" {
                Toggle(isOn: $viewModel.fromRawTag.onChange(fromRawTagChanged)) {
                    Text("From RAW tag")
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .focusable()
                .focused($focusedField, equals: .rawTag)
                .padding([.leading], 8)
                .help("From RAW tag")
                
                Toggle(isOn: $viewModel.fromCommunityTag.onChange(fromCommunityTagChanged)) {
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
        if let currentPage = viewModel.currentPage {
            if let rawPageStaffLevel = UserDefaults.standard.string(forKey: "StaffLevel_" + currentPage.displayName) {
                if let pageStaffLevelFromRaw = StaffLevelCase(rawValue: rawPageStaffLevel) {
                    viewModel.pageStaffLevel = pageStaffLevelFromRaw
                    return
                }
                viewModel.pageStaffLevel = StaffLevelCase.mod
                return
            }
        }

        if let rawPagelessStaffLevel = UserDefaults.standard.string(forKey: "StaffLevel") {
            if let pageStaffLevelFromRaw = StaffLevelCase(rawValue: rawPagelessStaffLevel) {
                viewModel.pageStaffLevel = pageStaffLevelFromRaw
                storeStaffLevelForPage()
                return
            }
        }

        viewModel.pageStaffLevel = StaffLevelCase.mod
        storeStaffLevelForPage()
    }

    private func storeStaffLevelForPage() {
        if let currentPage = viewModel.currentPage {
            UserDefaults.standard.set(viewModel.pageStaffLevel.rawValue, forKey: "StaffLevel_" + currentPage.displayName)
        } else {
            UserDefaults.standard.set(viewModel.pageStaffLevel.rawValue, forKey: "StaffLevel")
        }
    }

    private func loadPages() async {
        logger.verbose("Loading page catalog from server", context: "System")

        do {
            let pagesUrl = URL(string: "https://vero.andydragon.com/static/data/pages.json")!
            let pagesCatalog = try await URLSession.shared.decode(ScriptsCatalog.self, from: pagesUrl)
            var hubManifests = [LoadedHubManifest]()
            for hubPair in pagesCatalog.hubManifests {
                hubManifests.append(LoadedHubManifest(hubManifest: hubPair.value))
            }
            viewModel.loadedHubManifests.removeAll()
            viewModel.loadedHubManifests.append(
                contentsOf: hubManifests.sorted(by: {
                    if $0.hub == "other" {
                        return false
                    }
                    if $1.hub == "other" {
                        return true
                    }
                    return $0.hub < $1.hub
                }))
            var pages = [LoadedPage]()
            for hubPair in (pagesCatalog.hubs) {
                for hubPage in hubPair.value {
                    pages.append(LoadedPage.from(hub: hubPair.key, page: hubPage))
                }
            }
            viewModel.loadedPages.removeAll()
            viewModel.loadedPages.append(contentsOf: pages.sorted(by: {
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
            viewModel.currentPage = viewModel.loadedPages.first(where: { $0.displayName == page }) ?? viewModel.loadedPages.first
            if viewModel.currentPage == nil {
                viewModel.pageValidation = .error("Page must not be 'default' or a page name is required")
            } else {
                viewModel.pageValidation = .valid
            }
            viewModel.currentHubManifest = viewModel.loadedHubManifests.first(where: { $0.id == viewModel.currentPage?.hub })

            logger.verbose("Loaded page catalog from server with \(viewModel.loadedPages.count) pages", context: "System")

            updateStaffLevelForPage()

            // Delay the start of the templates download so the window can be ready faster
            try await Task.sleep(nanoseconds: 200_000_000)

            logger.verbose("Loading template catalog from server", context: "System")

            let templatesUrl = URL(string: "https://vero.andydragon.com/static/data/templates.json")!
            viewModel.templatesCatalog = try await URLSession.shared.decode(TemplateCatalog.self, from: templatesUrl)
            viewModel.waitingForTemplates = false
            updateScripts()
            updateNewMembershipScripts()

            logger.verbose("Loaded template catalog from server with \(viewModel.templatesCatalog.pages.count) page templates", context: "System")

            do {
                // Delay the start of the disallowed lists download so the window can be ready faster
                try await Task.sleep(nanoseconds: 1_000_000_000)

                logger.verbose("Loading disallow lists from server", context: "System")

                let disallowListsUrl = URL(string: "https://vero.andydragon.com/static/data/disallowlists.json")!
                viewModel.disallowLists = try await URLSession.shared.decode([String: [String]].self, from: disallowListsUrl)

                logger.verbose("Loaded disallow lists from server with \(viewModel.disallowLists.count) entries", context: "System")
            } catch {
                // do nothing, the disallow list is not critical
                logger.error("Failed to load disallow list from server: \(error.localizedDescription)", context: "System")
                debugPrint(error.localizedDescription)
            }

            do {
                logger.verbose("Loading caution lists from server", context: "System")

                let cautionListsUrl = URL(string: "https://vero.andydragon.com/static/data/cautionlists.json")!
                viewModel.cautionLists = try await URLSession.shared.decode([String: [String]].self, from: cautionListsUrl)

                logger.verbose("Loaded caution lists from server with \(viewModel.cautionLists.count) entries", context: "System")
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
        viewModel.membershipValidation = viewModel.validateMembership(value: viewModel.membership)
        if value != lastMembership {
            clearPlaceholders()
            updateScripts()
            updateNewMembershipScripts()
            lastMembership = value
        }
    }

    private func userNameChanged(to value: String) {
        viewModel.userNameValidation = viewModel.validateUserName(value: viewModel.userName)
        if value != lastUserName {
            clearPlaceholders()
            updateScripts()
            updateNewMembershipScripts()
            lastUserName = value
        }
    }

    private func yourNameChanged(to value: String) {
        viewModel.yourNameValidation = viewModel.validateUserName(value: viewModel.userName)
        if value != lastYourName {
            clearPlaceholders()
            UserDefaults.standard.set(viewModel.yourName, forKey: "YourName")
            updateScripts()
            updateNewMembershipScripts()
            lastYourName = value
        }
    }

    private func yourFirstNameChanged(to value: String) {
        if value != lastYourFirstName {
            clearPlaceholders()
            UserDefaults.standard.set(viewModel.yourFirstName, forKey: "YourFirstName")
            updateScripts()
            updateNewMembershipScripts()
            lastYourFirstName = value
        }
    }

    private func pageChanged(to value: LoadedPage?) {
        if viewModel.currentPage == nil {
            viewModel.pageValidation = .error("Page is required")
        } else {
            viewModel.pageValidation = .valid
        }
        if value != lastPage {
            clearPlaceholders()
            UserDefaults.standard.set(viewModel.currentPage?.displayName, forKey: "Page")
            updateStaffLevelForPage()
            viewModel.userNameValidation = viewModel.validateUserName(value: viewModel.userName)
            if !MembershipCase.caseValidFor(hub: viewModel.currentPage?.hub, viewModel.membership) {
                viewModel.membership = .none
                membershipChanged(to: viewModel.membership)
            }
            updateScripts()
            updateNewMembershipScripts()
            lastPage = value
            viewModel.currentHubManifest = viewModel.loadedHubManifests.first(where: { $0.id == viewModel.currentPage?.hub })
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
            if !viewModel.userNameValidation.isValid {
                validationErrors += "User: " + viewModel.userNameValidation.unwrappedMessage + "\n"
            }
            if !viewModel.membershipValidation.isValid {
                validationErrors += "Level: " + viewModel.membershipValidation.unwrappedMessage + "\n"
            }
            if !viewModel.yourNameValidation.isValid {
                validationErrors += "You: " + viewModel.yourNameValidation.unwrappedMessage + "\n"
            }
            if !viewModel.yourFirstNameValidation.isValid {
                validationErrors += "Your first name: " + viewModel.yourFirstNameValidation.unwrappedMessage + "\n"
            }
            if !viewModel.pageValidation.isValid {
                validationErrors += "Page: " + viewModel.pageValidation.unwrappedMessage + "\n"
            }
            featureScript = validationErrors
            originalPostScript = ""
            commentScript = ""
        } else if let currentPage = viewModel.currentPage {
            let currentPageName = currentPage.id
            let currentPageDisplayName = currentPage.name
            let scriptPageName = currentPage.pageName ?? currentPageDisplayName
            let scriptPageHash = currentPage.hashTag ?? currentPageDisplayName
            let scriptPageTitle = currentPage.title ?? currentPageDisplayName
            let membershipString = (currentPage.hub == "snap" && viewModel.membership.rawValue.hasPrefix("Snap "))
            ? String(viewModel.membership.rawValue.dropFirst(5))
            : viewModel.membership.rawValue
            let featureScriptTemplate = getTemplateFromCatalog(
                "feature",
                from: currentPage.id,
                firstFeature: viewModel.firstForPage,
                rawTag: viewModel.fromRawTag,
                communityTag: viewModel.fromCommunityTag,
                hubTag: viewModel.fromHubTag) ?? ""
            let commentScriptTemplate = getTemplateFromCatalog(
                "comment",
                from: currentPage.id,
                firstFeature: viewModel.firstForPage,
                rawTag: viewModel.fromRawTag,
                communityTag: viewModel.fromCommunityTag,
                hubTag: viewModel.fromHubTag) ?? ""
            let originalPostScriptTemplate = getTemplateFromCatalog(
                "original post",
                from: currentPage.id,
                firstFeature: viewModel.firstForPage,
                rawTag: viewModel.fromRawTag,
                communityTag: viewModel.fromCommunityTag,
                hubTag: viewModel.fromHubTag) ?? ""

            featureScript = featureScriptTemplate
                .replacingOccurrences(of: "%%PAGENAME%%", with: scriptPageName)
                .replacingOccurrences(of: "%%FULLPAGENAME%%", with: currentPageName)
                .replacingOccurrences(of: "%%PAGETITLE%%", with: scriptPageTitle)
                .replacingOccurrences(of: "%%PAGEHASH%%", with: scriptPageHash)
                .replacingOccurrences(of: "%%MEMBERLEVEL%%", with: membershipString)
                .replacingOccurrences(of: "%%USERNAME%%", with: viewModel.userName)
                .replacingOccurrences(of: "%%YOURNAME%%", with: viewModel.yourName)
                .replacingOccurrences(of: "%%YOURFIRSTNAME%%", with: viewModel.yourFirstName)
                .replacingOccurrences(of: "%%STAFFLEVEL%%", with: viewModel.pageStaffLevel.rawValue)
            originalPostScript = originalPostScriptTemplate
                .replacingOccurrences(of: "%%PAGENAME%%", with: scriptPageName)
                .replacingOccurrences(of: "%%FULLPAGENAME%%", with: currentPageName)
                .replacingOccurrences(of: "%%PAGETITLE%%", with: scriptPageTitle)
                .replacingOccurrences(of: "%%PAGEHASH%%", with: scriptPageHash)
                .replacingOccurrences(of: "%%MEMBERLEVEL%%", with: membershipString)
                .replacingOccurrences(of: "%%USERNAME%%", with: viewModel.userName)
                .replacingOccurrences(of: "%%YOURNAME%%", with: viewModel.yourName)
                .replacingOccurrences(of: "%%YOURFIRSTNAME%%", with: viewModel.yourFirstName)
                .replacingOccurrences(of: "%%STAFFLEVEL%%", with: viewModel.pageStaffLevel.rawValue)
            commentScript = commentScriptTemplate
                .replacingOccurrences(of: "%%PAGENAME%%", with: scriptPageName)
                .replacingOccurrences(of: "%%FULLPAGENAME%%", with: currentPageName)
                .replacingOccurrences(of: "%%PAGETITLE%%", with: scriptPageTitle)
                .replacingOccurrences(of: "%%PAGEHASH%%", with: scriptPageHash)
                .replacingOccurrences(of: "%%MEMBERLEVEL%%", with: membershipString)
                .replacingOccurrences(of: "%%USERNAME%%", with: viewModel.userName)
                .replacingOccurrences(of: "%%YOURNAME%%", with: viewModel.yourName)
                .replacingOccurrences(of: "%%YOURFIRSTNAME%%", with: viewModel.yourFirstName)
                .replacingOccurrences(of: "%%STAFFLEVEL%%", with: viewModel.pageStaffLevel.rawValue)
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
        if viewModel.waitingForTemplates {
            return "";
        }
        let templatePage = viewModel.templatesCatalog.pages.first(where: { page in
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
        if viewModel.waitingForTemplates {
            newMembershipScript = ""
            return
        }
        if !canCopyNewMembershipScript {
            var validationErrors = ""
            if viewModel.newMembership != NewMembershipCase.none {
                if !viewModel.userNameValidation.isValid {
                    validationErrors += "User: " + viewModel.userNameValidation.unwrappedMessage + "\n"
                }
                if !viewModel.newMembershipValidation.isValid {
                    validationErrors += "New level: " + viewModel.newMembershipValidation.unwrappedMessage + "\n"
                }
            }
            newMembershipScript = validationErrors
        } else if canCopyNewMembershipScript, let currentPage = viewModel.currentPage {
            let currentPageName = currentPage.id
            let currentPageDisplayName = currentPage.name
            let scriptPageName = currentPage.pageName ?? currentPageDisplayName
            let scriptPageHash = currentPage.hashTag ?? currentPageDisplayName
            let scriptPageTitle = currentPage.title ?? currentPageDisplayName
            let templateName = NewMembershipCase.scriptFor(hub: currentPage.hub, viewModel.newMembership)
            let template = viewModel.templatesCatalog.specialTemplates.first(where: { template in
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
                .replacingOccurrences(of: "%%USERNAME%%", with: viewModel.userName)
                .replacingOccurrences(of: "%%YOURNAME%%", with: viewModel.yourName)
                .replacingOccurrences(of: "%%YOURFIRSTNAME%%", with: viewModel.yourFirstName)
                .replacingOccurrences(of: "%%STAFFLEVEL%%", with: viewModel.pageStaffLevel.rawValue)
        } else {
            newMembershipScript = ""
        }
    }
}
