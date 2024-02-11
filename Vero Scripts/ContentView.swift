//
//  ContentView.swift
//  Vero Scripts
//
//  Created by Andrew Forget on 2024-01-03.
//

import SwiftUI

struct ContentView: View {
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
    @State var showingPlaceholderSheet = false
    @State var waitingForPages: Bool = true
    @State var pagesCatalog = PageCatalog(pages: [])
    @State var waitingForTemplates: Bool = true
    @State var templatesCatalog = TemplateCatalog(pages: [], specialTemplates: [])
    @State var disallowList = [String]()
    @ObservedObject var placeholders = PlaceholderList()
    @State var scriptWithPlaceholdersInPlace = ""
    @State var scriptWithPlaceholders = ""
    @State var lastMembership = MembershipCase.none
    @State var lastUserName = ""
    @State var lastYourName = ""
    @State var lastYourFirstName = ""
    @State var lastPage = ""
    @State var lastPageName = ""
    @State var lastPageStaffLevel = StaffLevelCase.mod
    @FocusState var focusedField: FocusedField?
    
    var canCopyScripts: Bool {
        return membershipValidation.valid
        && userNameValidation.valid
        && yourNameValidation.valid
        && yourFirstNameValidation.valid
        && pageValidation.valid
    }
    
    enum FocusedField {
        case userName
    }

    @Environment(\.colorScheme) var ColorScheme

    var body: some View {
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
                        validate: { value in
                            if value.count == 0 {
                                return (false, "Required value")
                            } else if value.first! == "@" {
                                return (false, "Don't include the '@' in user names")
                            } else if (disallowList.first { disallow in disallow == value } != nil) {
                                return (false, "User is on the disallow list")
                            }
                            return (true, nil)
                        }
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
                        if value == MembershipCase.none {
                            membershipValidation = (false, "Required value")
                        } else {
                            membershipValidation = (true, nil)
                        }
                        membershipChanged(to: value)
                    }) {
                        ForEach(MembershipCase.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .onAppear {
                        if membership == MembershipCase.none {
                            membershipValidation = (false, "Required value")
                        } else {
                            membershipValidation = (true, nil)
                        }
                    }
                    .focusable()
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
                        }
                    )

                    // Your first name editor
                    FieldEditor(
                        title: "Your first name:",
                        placeholder: "Enter your first name (capitalized)",
                        field: $yourFirstName,
                        fieldChanged: yourFirstNameChanged,
                        fieldValidation: $yourFirstNameValidation
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
                    
#if !os(iOS)
                    // Options
                    Toggle(isOn: $firstForPage.onChange(firstForPageChanged)) {
                        Text("First feature on page")
                    }
                    .focusable()
                    .padding([.leading], 8)

                    Toggle(isOn: $fromCommunityTag.onChange(communityTagChanged)) {
                        Text("From community tag")
                    }
                    .focusable()
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
                Toggle(isOn: $fromCommunityTag.onChange(communityTagChanged)) {
                    Text("From community tag")
                }
                .focusable()
                Spacer()
            }
#endif
            
            Group {
                // Feature script output
                ScriptEditor(title: "Feature script:", script: $featureScript, minHeight: 200, maxHeight: .infinity, canCopy: canCopyScripts, copy: { force, withPlaceholders in
                    copyScript(featureScript, [commentScript, originalPostScript], force: force, withPlaceholders: withPlaceholders)
                })
                
                // Comment script output
                ScriptEditor(title: "Comment script:", script: $commentScript, minHeight: 80, maxHeight: 160, canCopy: canCopyScripts, copy: { force, withPlaceholders in
                    copyScript(commentScript, [featureScript, originalPostScript], force: force, withPlaceholders: withPlaceholders)
                })
                
                // Original post script output
                ScriptEditor(title: "Original post script:", script: $originalPostScript, minHeight: 40, maxHeight: 80, canCopy: canCopyScripts, copy: { force, withPlaceholders in
                    copyScript(originalPostScript, [featureScript, commentScript], force: force, withPlaceholders: withPlaceholders)
                })
            }
            
            Group {
                // New membership picker and script output
                NewMembershipEditor(newMembership: $newMembership, script: $newMembershipScript, onChanged: newMembershipChanged, copy: {
                    copyToClipboard(newMembershipScript)
                })
            }
        }
        .padding()
        .textFieldStyle(.roundedBorder)
        .onAppear {
            focusedField = .userName
        }
        .alert(
            alertTitle,
            isPresented: $showingAlert,
            actions: {
            },
            message: {
                Text(alertMessage)
            })
        .sheet(isPresented: $showingPlaceholderSheet) {
            PlaceholderSheet(placeholders: placeholders, scriptWithPlaceholders: $scriptWithPlaceholders, scriptWithPlaceholdersInPlace: $scriptWithPlaceholdersInPlace, isPresenting: $showingPlaceholderSheet)
        }
        .disabled(waitingForPages)
        .task {
            lastPageStaffLevel = pageStaffLevel
            
            do {
                let pagesUrl = URL(string: "https://vero.andydragon.com/static/data/pages.json")!
                pagesCatalog = try await URLSession.shared.decode(PageCatalog.self, from: pagesUrl)
                waitingForPages = false
                
                // Delay the start of the templates download so the window can be ready faster
                try await Task.sleep(nanoseconds: 1_000_000_000)
                
                let templatesUrl = URL(string: "https://vero.andydragon.com/static/data/templates.json")!
                templatesCatalog = try await URLSession.shared.decode(TemplateCatalog.self, from: templatesUrl)
                waitingForTemplates = false
                updateScripts()
                updateNewMembershipScripts()

                do {
                    // Delay the start of the disallowed list download so the window can be ready faster
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    
                    let disallowListUrl = URL(string: "https://vero.andydragon.com/static/data/disallowlist.json")!
                    disallowList = try await URLSession.shared.decode([String].self, from: disallowListUrl)
                    updateScripts()
                    updateNewMembershipScripts()
                } catch {
                    // do nothing, the disallow list is not critical
                }
            } catch {
                alertTitle = "Could not load the page catalog from the server"
                alertMessage = "The application requires the catalog to perform its operations: " + error.localizedDescription
                terminalAlert = true
                showingAlert = true
            }
        }
    }

    func membershipChanged(to value: MembershipCase) {
        if value != lastMembership {
            placeholders.placeholderDict.removeAll()
            updateScripts()
            lastMembership = value
        }
    }

    func userNameChanged(to value: String) {
        if value != lastUserName {
            placeholders.placeholderDict.removeAll()
            updateScripts()
            updateNewMembershipScripts()
            lastUserName = value
        }
    }

    func yourNameChanged(to value: String) {
        if value != lastYourName {
            placeholders.placeholderDict.removeAll()
            UserDefaults.standard.set(yourName, forKey: "YourName")
            updateScripts()
            updateNewMembershipScripts()
            lastYourName = value
        }
    }

    func yourFirstNameChanged(to value: String) {
        if value != lastYourFirstName {
            placeholders.placeholderDict.removeAll()
            UserDefaults.standard.set(yourFirstName, forKey: "YourFirstName")
            updateScripts()
            updateNewMembershipScripts()
            lastYourFirstName = value
        }
    }

    func pageChanged(to value: String) {
        if value != lastPage {
            placeholders.placeholderDict.removeAll()
            UserDefaults.standard.set(page, forKey: "Page")
            updateScripts()
            lastPage = value
        }
    }

    func pageNameChanged(to value: String) {
        if value != lastPageName {
            placeholders.placeholderDict.removeAll()
            UserDefaults.standard.set(pageName, forKey: "PageName")
            updateScripts()
            lastPageName = value
        }
    }

    func pageStaffLevelChanged(to value: StaffLevelCase) {
        if value != lastPageStaffLevel {
            placeholders.placeholderDict.removeAll()
            UserDefaults.standard.set(pageStaffLevel.rawValue, forKey: "StaffLevel")
            updateScripts()
            lastPageStaffLevel = value
        }
    }

    func firstForPageChanged(to value: Bool) {
        updateScripts()
    }

    func communityTagChanged(to value: Bool) {
        updateScripts()
    }

    func newMembershipChanged(to value: NewMembershipCase) {
        updateNewMembershipScripts()
    }

    func copyScript(_ script: String, _ otherScripts: [String], force: Bool = false, withPlaceholders: Bool = false) -> Void {
        scriptWithPlaceholders = script
        scriptWithPlaceholdersInPlace = script
        placeholders.placeholderDict.forEach({ placeholder in
            scriptWithPlaceholders = scriptWithPlaceholders.replacingOccurrences(of: placeholder.key, with: placeholder.value.value)
        })
        if withPlaceholders || !checkForPlaceholders(scripts: [scriptWithPlaceholdersInPlace] + otherScripts, force: force) {
            copyToClipboard(withPlaceholders ? scriptWithPlaceholdersInPlace : scriptWithPlaceholders)
        }
    }
    
    func checkForPlaceholders(scripts: [String], force: Bool = false) -> Bool {
        var foundPlaceholders: [String] = [];
        scripts.forEach({ script in foundPlaceholders.append(contentsOf: matches(of: "\\[\\[([^\\]]*)\\]\\]", in: script))})
        if foundPlaceholders.count != 0 {
            var needEditor: Bool = false
            for placeholder in foundPlaceholders {
                let placeholderEntry = placeholders.placeholderDict[placeholder]
                if placeholderEntry == nil {
                    needEditor = true
                    placeholders.placeholderDict[placeholder] = PlaceholderValue()
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
        if newMembership == NewMembershipCase.none 
            || !userNameValidation.valid {
            newMembershipScript = ""
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
